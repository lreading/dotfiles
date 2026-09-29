#!/usr/bin/env bash
set -uo pipefail

case "${1:-}" in
  work) class=kitty-work; title=notes ;;
  personal) class=kitty-personal; title=tmux-personal ;;
  *) exit 2 ;;
esac

started=$SECONDS
kitty --class "$class" --title "$title" -e "$HOME/.config/hypr/UserScripts/WorkTmux.sh" "$1"
status=$?

# Upstream's theme refresh can signal Kitty while it is still starting.
if (( status == 138 && SECONDS - started < 10 )); then
  printf 'RETRY %s after early SIGUSR1\n' "$class" >&2
  exec kitty --class "$class" --title "$title" -e "$HOME/.config/hypr/UserScripts/WorkTmux.sh" "$1"
fi

exit "$status"
