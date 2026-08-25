#!/usr/bin/env bash
set -u

# Prefer the user service whenever it exists. A direct fallback during a
# systemd stop/start race creates two Waybar processes at login.
if command -v systemctl >/dev/null 2>&1; then
    load_state="$(systemctl --user show waybar.service --property=LoadState --value 2>/dev/null || true)"
    if [ -n "$load_state" ] && [ "$load_state" != not-found ]; then
        systemctl --user start waybar.service >/dev/null 2>&1 || true
        exit 0
    fi
fi

pgrep -x waybar >/dev/null 2>&1 && exit 0
command -v waybar >/dev/null 2>&1 || exit 1
exec waybar
