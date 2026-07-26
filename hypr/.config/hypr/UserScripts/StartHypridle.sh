#!/usr/bin/env bash
set -euo pipefail

# The vendor startup launches the default Hypridle config.  Replace it after
# startup with the Stow-managed user config, leaving exactly one daemon.
sleep 3
pkill -TERM -x hypridle >/dev/null 2>&1 || true

for _ in {1..30}; do
  pgrep -x hypridle >/dev/null 2>&1 || break
  sleep 0.1
done

if pgrep -x hypridle >/dev/null 2>&1; then
  # Hypridle 0.1.7 can ignore SIGTERM while its idle listeners are active.
  # It is safe to force-stop the daemon here; no user data lives in it.
  pkill -KILL -x hypridle >/dev/null 2>&1 || true
fi

exec hypridle -c "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/UserConfigs/hypridle.conf"
