#!/usr/bin/env bash
set -euo pipefail

# The upstream script stores its emoji database as bare text after `exit`.
# Bash still parses that text and currently fails on entries containing `)`.
# Reuse the upstream database without asking Bash to parse it as source.
upstream_script="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/RofiEmoji.sh"
rofi_theme="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config-emoji.rasi"
message='** note ** 👀 Click or Return to choose || Ctrl V to Paste'

pkill -x rofi >/dev/null 2>&1 || true

sed '1,/^# # DATA # #$/d' "$upstream_script" |
  rofi -i -dmenu -mesg "$message" -config "$rofi_theme" |
  awk '{print $1}' |
  head -n 1 |
  tr -d '\n' |
  wl-copy
