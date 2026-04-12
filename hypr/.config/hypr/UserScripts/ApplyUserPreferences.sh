#!/usr/bin/env bash
# Re-apply local preferences that upstream copy/upgrade/wallpaper scripts can reset.

set -euo pipefail

waybar_config_target="$HOME/.config/waybar/configs/[TOP] Default Laptop"
waybar_style_target="$HOME/.config/waybar/style/[Dark] Latte-Wallust combined.css"
waybar_pinned_colors="$HOME/.config/hypr/UserPrefs/colors-waybar.css"

kitty_pinned_conf="$HOME/.config/hypr/UserPrefs/kitty.conf"
kitty_pinned_wallust="$HOME/.config/hypr/UserPrefs/kitty-01-Wallust.conf"

rainbow_script="$HOME/.config/hypr/UserScripts/RainbowBorders.sh"
wallust_script="$HOME/.config/hypr/scripts/WallustSwww.sh"

mkdir -p "$HOME/.config/waybar/wallust" "$HOME/.config/kitty/kitty-themes"

if [[ -e "$waybar_config_target" ]]; then
  ln -sfn "$waybar_config_target" "$HOME/.config/waybar/config"
fi

if [[ -e "$waybar_style_target" ]]; then
  ln -sfn "$waybar_style_target" "$HOME/.config/waybar/style.css"
fi

if [[ -s "$waybar_pinned_colors" ]]; then
  cp -f "$waybar_pinned_colors" "$HOME/.config/waybar/wallust/colors-waybar.css"
fi

# Keep current Kitty preferences stable across wallpaper-triggered wallust runs.
if [[ -s "$kitty_pinned_conf" ]]; then
  cp -f "$kitty_pinned_conf" "$HOME/.config/kitty/kitty.conf"
fi

if [[ -s "$kitty_pinned_wallust" ]]; then
  cp -f "$kitty_pinned_wallust" "$HOME/.config/kitty/kitty-themes/01-Wallust.conf"
fi

# Vendor WallustSwww.sh performs a delayed Hyprland reload after wallpaper changes.
# Re-apply saved preferences after that reload so wallpaper changes do not reset
# Waybar/Kitty colors or wipe the animated rainbow border.
if [[ -f "$wallust_script" ]] && ! grep -q 'ApplyUserPreferences: reapply rainbow after delayed reload' "$wallust_script"; then
  tmp="$(mktemp)"
  awk '
    {
      print
      if ($0 ~ /hyprctl reload .* true/) {
        print "    # ApplyUserPreferences: reapply rainbow after delayed reload"
        print "    if [ -x \"$HOME/.config/hypr/UserScripts/ApplyUserPreferences.sh\" ]; then"
        print "      sleep 0.2"
        print "      \"$HOME/.config/hypr/UserScripts/ApplyUserPreferences.sh\" >/dev/null 2>&1 || true"
        print "    fi"
      }
    }
  ' "$wallust_script" > "$tmp"
  cat "$tmp" > "$wallust_script"
  rm -f "$tmp"
fi

if [[ -x "$rainbow_script" ]]; then
  "$rainbow_script" >/tmp/rainbow-borders.log 2>&1 || true
fi

if pgrep -x waybar >/dev/null 2>&1; then
  pkill -SIGUSR2 waybar 2>/dev/null || true
fi
