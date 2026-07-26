#!/usr/bin/env bash
set -euo pipefail

# Hyprland's native cycle_next() only considers the active workspace.  This
# setup normally has one window per workspace, so cycle all mapped windows on
# regular workspaces in deterministic workspace/address order instead.
active_address="$(hyprctl activewindow -j | jq -r '.address // empty')"
[[ "$active_address" =~ ^0x[0-9A-Fa-f]+$ ]] || exit 0

mapfile -t window_addresses < <(
  hyprctl clients -j |
    jq -r '
      [
        .[]
        | select(.mapped == true and .workspace.id > 0)
        | { address, workspace_id: .workspace.id }
      ]
      | sort_by(.workspace_id, .address)
      | .[].address
    '
)

((${#window_addresses[@]} > 1)) || exit 0

active_index=-1
for index in "${!window_addresses[@]}"; do
  if [[ "${window_addresses[$index]}" == "$active_address" ]]; then
    active_index=$index
    break
  fi
done

if ((active_index < 0)); then
  next_index=0
else
  next_index=$(((active_index + 1) % ${#window_addresses[@]}))
fi

next_address="${window_addresses[$next_index]}"
[[ "$next_address" =~ ^0x[0-9A-Fa-f]+$ ]] || exit 1

hyprctl dispatch "hl.dsp.focus({ window = \"address:${next_address}\" })"
