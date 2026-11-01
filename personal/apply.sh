#!/usr/bin/env bash
# personal/apply.sh - put this machine's personal configuration on top of a fresh end-4 install.
#
# Run it after end-4's install.sh has put dots/ in place:
#   bash personal/apply.sh [--dry-run] [--home DIR] [--skip-system] [--skip-services] [--skip-links]
#
# What it does, in order:
#   1. links <config>/cyrus-dotfiles -> this repository (the .zshrc tracker finds personal.sh through it)
#   2. copies every full file under personal/home/ into $HOME (existing files are backed up first)
#   3. applies every personal/home/**/*.patch to the matching file under $HOME (patch -p1 -d $HOME)
#   4. fastfetch: when personal/home/.config/fastfetch exists, runs personal/setup-fastfetch.sh
#   5. enables the user services that personal/ ships (qs-watchdog.timer)
#   6. installs the hardware monitor system service (needs sudo; skipped with --skip-system)
# Nothing here touches upstream files except through the .patch files, and every replaced file
# is kept under ~/.local/state/illogical-impulse/backups/personal-apply-<timestamp>/.
set -u

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SRC=$REPO/personal/home
DRY=0 SKIP_SYSTEM=0 SKIP_SERVICES=0 SKIP_LINKS=0
TARGET_HOME=$HOME
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY=1 ;;
    --home) TARGET_HOME=$2; shift ;;
    --skip-system) SKIP_SYSTEM=1 ;;
    --skip-services) SKIP_SERVICES=1 ;;
    --skip-links) SKIP_LINKS=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
CONFIG_HOME=${XDG_CONFIG_HOME:-$TARGET_HOME/.config}
[[ $TARGET_HOME == "$HOME" ]] || CONFIG_HOME=$TARGET_HOME/.config
STAMP=$(date +%Y%m%dT%H%M%S)
BACKUP=$TARGET_HOME/.local/state/illogical-impulse/backups/personal-apply-$STAMP
FAILED=0

say()  { printf '%s\n' "$*"; }
warn() { printf 'WARN %s\n' "$*" >&2; }
run()  { if (( DRY )); then say "  (dry) $*"; else "$@"; fi; }

backup() { # keep a copy of a file that is about to change
  local f=$1 rel=${1#"$TARGET_HOME"/}
  [[ -f $f ]] || return 0
  run mkdir -p "$BACKUP/$(dirname "$rel")"
  run cp -p "$f" "$BACKUP/$rel"
}

say "== repository: $REPO"
say "== target home: $TARGET_HOME"

# 1. repository link -------------------------------------------------------------------------
if (( ! SKIP_LINKS )); then
  link=$CONFIG_HOME/cyrus-dotfiles
  if [[ -e $link && ! -L $link ]]; then
    warn "$link exists and is not a symlink; leaving it alone"
  else
    run mkdir -p "$CONFIG_HOME"
    run ln -sfnr -- "$REPO" "$link"
    say "link  $link -> $REPO"
  fi
fi

# 2. full files ------------------------------------------------------------------------------
say "== files"
while IFS= read -r -d '' src; do
  rel=${src#"$SRC"/}
  case $rel in .config/fastfetch/*) continue ;; esac   # linked, not copied (step 4)
  dst=$TARGET_HOME/$rel
  if [[ -f $dst ]] && cmp -s "$src" "$dst"; then
    say "same  $rel"
    continue
  fi
  backup "$dst"
  run mkdir -p "$(dirname "$dst")"
  run cp -p "$src" "$dst"
  say "copy  $rel"
done < <(find "$SRC" -type f ! -name '*.patch' -print0 | sort -z)

# 3. patches ----------------------------------------------------------------------------------
say "== patches"
while IFS= read -r -d '' pf; do
  rel=${pf#"$SRC"/}; rel=${rel%.patch}
  dst=$TARGET_HOME/$rel
  if [[ ! -f $dst ]]; then
    warn "no target for $rel.patch (is end-4 installed?)"; FAILED=1; continue
  fi
  if patch -R -s -f --dry-run -p1 -d "$TARGET_HOME" < "$pf" >/dev/null 2>&1; then
    say "done  $rel.patch (already applied)"
  elif patch -N -s -f --dry-run -p1 -d "$TARGET_HOME" < "$pf" >/dev/null 2>&1; then
    backup "$dst"
    if (( DRY )); then say "  (dry) patch $rel"; else
      patch -N -s -f -p1 -d "$TARGET_HOME" --no-backup-if-mismatch < "$pf" && say "patch $rel.patch"
    fi
  else
    warn "$rel.patch does not apply to the installed file; apply it by hand:"
    patch -N -f --dry-run -p1 -d "$TARGET_HOME" < "$pf" 2>&1 | sed 's/^/      /' >&2
    FAILED=1
  fi
done < <(find "$SRC" -name '*.patch' -print0 | sort -z)

# executable helpers
for f in "$SRC"/.local/bin/*; do
  [[ -f $f && -f $TARGET_HOME/.local/bin/$(basename "$f") ]] && run chmod +x "$TARGET_HOME/.local/bin/$(basename "$f")"
done

# 4. fastfetch (the user's own setup; personal/setup-fastfetch.sh owns the links) ------------------
if (( ! SKIP_LINKS )) && [[ -d $SRC/.config/fastfetch ]]; then
  say "== fastfetch"
  if [[ ! -f $REPO/personal/setup-fastfetch.sh ]]; then
    warn "personal/setup-fastfetch.sh missing; link $CONFIG_HOME/fastfetch yourself"
  elif (( DRY )); then say "  (dry) bash personal/setup-fastfetch.sh"
  else
    HOME=$TARGET_HOME XDG_CONFIG_HOME=$CONFIG_HOME bash "$REPO/personal/setup-fastfetch.sh" || { warn "setup-fastfetch.sh failed"; FAILED=1; }
  fi
fi

# 5. user services ----------------------------------------------------------------------------
if (( ! SKIP_SERVICES )); then
  say "== user services"
  if command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1; then
    run systemctl --user daemon-reload
    run systemctl --user enable --now qs-watchdog.timer
    say "enabled qs-watchdog.timer (clash-verge.service is started from hypr/custom/execs.lua)"
  else
    warn "no systemd user session; enable qs-watchdog.timer yourself"
  fi
fi

# 6. hardware monitor system service (from dots/, shipped by the feat/hardware-monitor change) ----
if (( ! SKIP_SYSTEM )); then
  say "== hardware monitor (system service, needs sudo)"
  res=$REPO/dots/.config/quickshell/ii/scripts/resources
  if [[ -f $res/end4-hardware-monitor.py && -f $res/end4-hardware-monitor.service ]]; then
    run sudo install -Dm755 "$res/end4-hardware-monitor.py" /usr/local/libexec/end4-hardware-monitor.py
    run sudo install -Dm644 "$res/end4-hardware-monitor.service" /etc/systemd/system/end4-hardware-monitor.service
    run sudo systemctl daemon-reload
    run sudo systemctl enable --now end4-hardware-monitor.service
  else
    warn "hardware monitor files not found under $res"
  fi
fi

# summary ---------------------------------------------------------------------------------------
say ""
if (( DRY )); then say "== done (dry run)"; else say "== done. Backups: $BACKUP"; fi
say "Still manual:"
say "  - packages:   bash $REPO/personal.sh ; then yay -S --needed \$(sed -n 's/^#AUR //p' $REPO/personal.sh | tr '\\n' ' ')"
say "  - sunshine:   fill the <LAN-IP>/<TAILSCALE-IP>/<TAILNET-HOST> placeholders in ~/.config/sunshine/sunshine.conf"
say "  - monitors:   ~/.config/hypr/monitors.lua is for this machine's HDMI-A-1 4K display; run nwg-displays on other hardware"
say "  - apps:       feishu launcher expects ~/.local/opt/feishu; clash needs Clash Verge Rev + a subscription (not in git)"
say "  - restart:    log out and back in (or hyprctl reload + Ctrl+Super+R) so Hyprland, quickshell, fcitx5 and zsh pick everything up"
(( FAILED )) && { warn "some steps need attention (see above)"; exit 1; }
exit 0
