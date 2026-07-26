#!/usr/bin/env bash
# User-maintained quick keybind reference. Keep this in the Stow layer so it
# documents the active user overrides instead of the upstream defaults.
set -euo pipefail

if pidof rofi >/dev/null 2>&1; then pkill rofi || true; fi
if pidof yad >/dev/null 2>&1; then pkill yad || true; fi

GDK_BACKEND=wayland yad \
  --center \
  --title="KooL Quick Cheat Sheet" \
  --no-buttons \
  --list \
  --column=Key: \
  --column=Description: \
  --column=Comment: \
  --timeout-indicator=bottom \
  "ESC" "Close this app" "" \
  "󰖳 SHIFT H" "Quick cheat sheet" "This widget" \
  "󰖳 SHIFT K" "Searchable keybinds" "Live Hyprland bind list" \
  "󰖳 H" "Focus left" "Vim-style focus" \
  "󰖳 J" "Focus down" "Vim-style focus" \
  "󰖳 K" "Focus up" "Vim-style focus" \
  "󰖳 L" "Focus right" "Vim-style focus" \
  "ALT Tab" "Cycle next window" "Across regular workspaces" \
  "󰖳 SHIFT L" "Lock screen" "User bind" \
  "CTRL ALT L" "Lock screen" "User override" \
  "󰖳 F" "Fake fullscreen" "Maximized window" \
  "󰖳 SHIFT F" "Fullscreen" "Full client fullscreen" \
  "󰖳 CTRL F" "Fake fullscreen" "Maximized window" \
  "󰖳 ALT L" "Change layout" "Dwindle / master / scrolling / monocle" \
  "󰖳 SHIFT Return" "Dropdown terminal" "Kitty" \
  "󰖳 D" "Application launcher" "Rofi" \
  "󰖳 B" "Open default browser" "" \
  "󰖳 E" "Open file manager" "Thunar" \
  "󰖳 S" "Web search" "Rofi" \
  "󰖳 W" "Choose wallpaper" "" \
  "󰖳 SHIFT W" "Choose wallpaper effects" "" \
  "CTRL ALT W" "Random wallpaper" "" \
  "󰖳 CTRL ALT B" "Toggle Waybar" "" \
  "󰖳 CTRL B" "Waybar styles" "" \
  "󰖳 ALT B" "Waybar layout" "" \
  "󰖳 N" "Notification panel" "User override" \
  "󰖳 SHIFT N" "Notification panel" "SwayNC" \
  "󰖳 SHIFT Print" "Screenshot area" "" \
  "󰖳 SHIFT S" "Screenshot with Swappy" "" \
  "ALT Print" "Screenshot active window" "" \
  "CTRL ALT P" "Power menu" "" \
  "󰖳 SHIFT G" "Game mode" "" \
  "󰖳 ALT E" "Emoji menu" "" \
  "󰖳 CTRL O" "Toggle opaque" "Active window" \
  "󰖳 SHIFT A" "Animations menu" "" \
  "󰖳 CTRL R" "Rofi themes" "" \
  "󰖳 CTRL SHIFT R" "Rofi themes (modified)" "" \
  "󰖳 CTRL SHIFT K" "Kitty theme selector" "Moved to avoid an upstream conflict" \
  "󰖳 M" "Set split ratio" "0.3" \
  "󰖳 ALT V" "Clipboard manager" "" \
  "󰖳 CTRL ALT Delete" "Exit Hyprland" "" \
  "More tips" "https://github.com/LinuxBeginnings/Hyprland-Dots/wiki" ""
