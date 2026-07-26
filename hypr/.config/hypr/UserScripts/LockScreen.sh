#!/usr/bin/env bash
set -euo pipefail

# Serialize launch attempts.  A stale, invisible hyprlock process otherwise
# makes the usual `pidof hyprlock || hyprlock` pattern silently do nothing.
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
exec 9>"$runtime_dir/hyprlock-launch.lock"
flock -n 9 || exit 0

if pgrep -x hyprlock >/dev/null 2>&1; then
  # A real session lock is already active.  Leave it alone.
  if [[ "$(hyprctl locked 2>/dev/null || true)" == "true" ]]; then
    exit 0
  fi

  # Hyprlock is running without an active session-lock surface.  Clear that
  # stale process before launching a fresh, immediately rendered lock screen.
  pkill -TERM -x hyprlock
  for _ in {1..20}; do
    pgrep -x hyprlock >/dev/null 2>&1 || break
    sleep 0.05
  done

  if pgrep -x hyprlock >/dev/null 2>&1; then
    notify-send -u critical "Lock screen" "A stale Hyprlock process could not be stopped."
    exit 1
  fi
fi

bash "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/UserScripts/WeatherWrap.sh" >/dev/null 2>&1 &
exec hyprlock --immediate-render
