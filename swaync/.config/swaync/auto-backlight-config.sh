#!/usr/bin/env bash

set -euo pipefail

source_config="${XDG_CONFIG_HOME:-$HOME/.config}/swaync/config.json"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
output_dir="$runtime_dir/swaync"
output_config="$output_dir/config.json"
temporary_config="$output_dir/config.json.tmp"

mkdir -p "$output_dir"

backlight_device=""
for device_path in /sys/class/backlight/*; do
    [[ -e "$device_path/brightness" ]] || continue
    backlight_device="${device_path##*/}"
    break
done

if [[ -n "$backlight_device" ]]; then
    jq --arg device "$backlight_device" \
        '."widget-config".backlight.device = $device
         | ."widget-config".backlight.subsystem = "backlight"' \
        "$source_config" > "$temporary_config"
else
    jq 'del(.widgets[]? | select(. == "backlight"))
        | del(."widget-config".backlight)' \
        "$source_config" > "$temporary_config"
fi

mv "$temporary_config" "$output_config"
