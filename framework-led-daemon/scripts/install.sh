#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bin_dir="${HOME}/.local/bin"
config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/framework-led-daemon"
systemd_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user"

cd "${project_dir}"
cargo build --release

mkdir -p "${bin_dir}" "${config_dir}" "${systemd_dir}"
install -m 0755 "target/release/framework-led-daemon" "${bin_dir}/framework-led-daemon"
install -m 0644 "systemd/framework-led-daemon.service" "${systemd_dir}/framework-led-daemon.service"

if [[ ! -f "${config_dir}/config.toml" ]]; then
  "${bin_dir}/framework-led-daemon" doctor --write-default-config >/dev/null
fi

systemctl --user daemon-reload
systemctl --user enable --now framework-led-daemon.service
loginctl enable-linger "${USER}" 2>/dev/null || {
  echo "warn: could not enable linger; service will start at login, not boot."
  echo "      run manually if needed: loginctl enable-linger ${USER}"
}

echo "Installed framework-led-daemon."
echo "Run diagnostics with: framework-led-daemon doctor"
