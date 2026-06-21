#!/usr/bin/env bash
set -euo pipefail

bin_path="${HOME}/.local/bin/framework-led-daemon"
systemd_path="${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user/framework-led-daemon.service"

systemctl --user disable --now framework-led-daemon.service 2>/dev/null || true
rm -f "${systemd_path}" "${bin_path}"
systemctl --user daemon-reload

echo "Uninstalled framework-led-daemon binary and user service."
echo "User config was left intact under ${XDG_CONFIG_HOME:-${HOME}/.config}/framework-led-daemon."
