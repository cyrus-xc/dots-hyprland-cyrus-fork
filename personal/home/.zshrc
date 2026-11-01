export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git sudo)
zstyle ':omz:update' mode disabled
source "$ZSH/oh-my-zsh.sh"

eval "$(starship init zsh)"
eval "$(zoxide init zsh --cmd cd)"

alias cat='bat'
alias c='clear'

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Local Clash-compatible proxy
source "$HOME/.config/clash-proxy.sh"

# Local Mihomo commands
[[ ! -f "$HOME/.config/clash-commands.zsh" ]] || source "$HOME/.config/clash-commands.zsh"

# Huggingface Config
export HF_ENDPOINT=https://hf-mirror.com

# Remove obsolete system-wide alias after home-directory migration.
unalias claude 2>/dev/null

# >>> personal.sh package tracker (dots-hyprland-cyrus-fork) >>>
# `pacman` and `sudo pacman` are wrapped: after each run, explicitly installed
# packages that were not there before are appended to personal.sh (repo
# packages to the pacman command, anything else as an "#AUR name" line).
# pacman's arguments and exit code are passed through unchanged.
PERSONAL_SH="${CYRUS_DOTFILES_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/cyrus-dotfiles}/personal.sh"

personal_pkg_snapshot() { command pacman -Qeq 2>/dev/null | sort }

personal_pkg_record() {  # $1 = before, $2 = after (sorted package lists)
  local pkg tmp
  [[ -w $PERSONAL_SH ]] || return 0
  for pkg in ${(f)"$(comm -13 <(print -r -- "$1") <(print -r -- "$2"))"}; do
    [[ -n $pkg ]] || continue
    sed -E 's/^(#AUR | +)//; s/ \\$//' "$PERSONAL_SH" | grep -qxF -- "$pkg" && continue
    tmp=$(mktemp "${PERSONAL_SH}.XXXXXX") || return 0
    if command pacman -Si -- "$pkg" >/dev/null 2>&1; then
      # repo package: continue the pacman command after its last package line
      awk -v pkg="$pkg" '
        /^sudo pacman -S --needed \\$/ { inlist = 1; print; next }
        inlist && !/\\$/ { print $0 " \\"; print "    " pkg; inlist = 0; next }
        { print }' "$PERSONAL_SH" > "$tmp"
    else
      # not in the sync repos (AUR, local build): add an #AUR line after the last one
      awk -v pkg="$pkg" '
        { line[NR] = $0 }
        /^#AUR / { last = NR }
        !hdr && /^sudo pacman -S --needed/ { hdr = NR }
        END {
          if (!last) last = hdr - 1
          for (i = 1; i <= NR; i++) { print line[i]; if (i == last) print "#AUR " pkg }
        }' "$PERSONAL_SH" > "$tmp"
    fi
    if [[ -s $tmp ]] && cat "$tmp" > "$PERSONAL_SH"; then
      print -u2 "personal.sh: added $pkg"
    fi
    rm -f "$tmp"
  done
}

personal_pacman() {  # run "$@" (pacman, or sudo pacman) and record new explicit packages
  local before after rc
  before=$(personal_pkg_snapshot)
  "$@"
  rc=$?
  after=$(personal_pkg_snapshot)
  personal_pkg_record "$before" "$after"
  return $rc
}
alias pacman='personal_pacman command pacman'

sudo() {  # `sudo [options] pacman ...` goes through the same tracker
  local arg
  for arg in "$@"; do
    [[ $arg == -* ]] && continue
    if [[ $arg == pacman ]]; then
      personal_pacman command sudo "$@"
      return
    fi
    break
  done
  command sudo "$@"
}
# <<< personal.sh package tracker <<<

# >>> Cyrus Fastfetch >>>
# Resolve paths from HOME/XDG; no machine-specific repository location.
typeset -U path PATH
path=("$HOME/.local/bin" $path)
[[ ! -r "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/startup.zsh" ]] || source "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/startup.zsh"
# <<< Cyrus Fastfetch <<<
