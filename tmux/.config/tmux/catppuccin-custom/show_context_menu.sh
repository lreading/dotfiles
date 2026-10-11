#!/bin/sh

set -eu

target_client=${1:?missing target client}
target_pane=${2:?missing target pane}
config_dir="$HOME/.config/tmux/catppuccin-custom"

public_ip=$(sh "$config_dir/pub_ip.sh")
private_ip=$(sh "$config_dir/priv_ip.sh")

tmux display-menu -c "$target_client" -t "$target_pane" \
  -T 'Tmux context · #S' -x C -y C -b rounded \
  -s 'fg=#{@thm_fg},bg=#{@thm_mantle}' \
  -S 'fg=#{@thm_blue},bg=#{@thm_mantle}' \
  -H 'fg=#{@thm_mantle},bg=#{@thm_blue}' \
  "Public IP   $public_ip" '' "run-shell 'exec ~/.config/tmux/catppuccin-custom/copy_context_value.sh public'" \
  "Private IP  $private_ip" '' "run-shell 'exec ~/.config/tmux/catppuccin-custom/copy_context_value.sh private'" \
  'Path        #{pane_current_path}' '' "run-shell 'exec ~/.config/tmux/catppuccin-custom/copy_context_value.sh path $target_pane'" \
  '' \
  '-Enter copies the selected item. q or Esc closes.' '' ''
