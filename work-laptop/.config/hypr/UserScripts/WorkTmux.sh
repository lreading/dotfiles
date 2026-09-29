#!/usr/bin/env bash
set -euo pipefail

# Let Continuum restore its sessions before either Kitty client attaches.
tmux new-session -d -s personal 2>/dev/null || true
for _ in {1..30}; do
  [[ "$(tmux show-option -gqv @dotfiles-resurrect-restored 2>/dev/null || true)" == 1 ]] && break
  sleep 0.1
done

case "${1:-}" in
  work)
    exec tmux new-session -A -s tkhq -n notes -c "$HOME" "cd \"$HOME/notes\" && exec nvim ."
    ;;
  personal)
    exec tmux new-session -A -s personal
    ;;
  *)
    printf 'Usage: %s {work|personal}\n' "$0" >&2
    exit 2
    ;;
esac
