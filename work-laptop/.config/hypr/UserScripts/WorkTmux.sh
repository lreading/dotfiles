#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  work)
    exec tmux new-session -A -s tkhq -n notes -c "$HOME" "cd \"$HOME/notes\" && exec nvim ."
    ;;
  personal)
    resurrect_dir=""
    for _ in {1..100}; do
      resurrect_dir="$(tmux show-option -gqv @resurrect-dir 2>/dev/null || true)"
      [[ -n "$resurrect_dir" ]] && break
      sleep 0.1
    done

    resurrect_dir="${resurrect_dir/#\~/$HOME}"
    if [[ -n "$resurrect_dir" && -e "$resurrect_dir/last" ]]; then
      restored=false
      for _ in {1..300}; do
        if [[ "$(tmux show-option -gqv @dotfiles-resurrect-restored 2>/dev/null || true)" == 1 ]]; then
          restored=true
          break
        fi
        sleep 0.1
      done
      [[ "$restored" == true ]] || printf 'TIMEOUT waiting for tmux restore\n' >&2
    fi

    exec tmux new-session -A -s personal
    ;;
  *)
    printf 'Usage: %s {work|personal}\n' "$0" >&2
    exit 2
    ;;
esac
