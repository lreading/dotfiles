#!/bin/sh

set -eu

config_dir="$HOME/.config/tmux/catppuccin-custom"

case "${1:-}" in
  public)
    value=$(sh "$config_dir/pub_ip.sh")
    ;;
  private)
    value=$(sh "$config_dir/priv_ip.sh")
    ;;
  path)
    target_pane=${2:?missing target pane}
    value=$(tmux display-message -p -t "$target_pane" '#{pane_current_path}')
    ;;
  *)
    exit 2
    ;;
esac

printf '%s' "$value" | wl-copy
