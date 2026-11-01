# Run only for an interactive terminal; scripts and pipes remain quiet.
if [[ -o interactive && -t 1 && ${TERM:-dumb} != dumb ]] && (( $+commands[fastfetch] )); then
  if [[ -n ${KITTY_WINDOW_ID:-} || ${TERM:-} == xterm-kitty ]] && [[ -z ${SSH_CONNECTION:-} ]]; then
    command fastfetch --config "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc"
  else
    command fastfetch --config "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc" --logo-type small --logo arch
  fi
fi
