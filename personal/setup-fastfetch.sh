#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
# Refuse to overwrite unrelated files; existing managed links may be refreshed.
link_directory() {
    local target=$1 link=$2
    mkdir -p -- "$(dirname -- "$link")"
    if [[ -e "$link" && ! -L "$link" ]]; then
        printf 'Already exists as a real directory: %s; merge it first.\n' "$link" >&2
        return 1
    fi
    ln -sfnr -- "$target" "$link"
}
link_directory "$repo_root/personal/home/.config/fastfetch" "$config_home/fastfetch"
link_directory "$repo_root/personal/home/Pictures/fastfetch" "$HOME/Pictures/fastfetch"
link_directory "$repo_root" "$config_home/cyrus-dotfiles"
printf '%s\n' 'Links ready. Install fastfetch via your package manager, then merge personal/home/.zshrc into ~/.zshrc.'
