#!/usr/bin/env bash
set -euo pipefail

readonly WORKSPACE_WORK=10
readonly WORKSPACE_PERSONAL=8
readonly WORKSPACE_SLACK=9
readonly WORK_TMUX_SESSION="${HYPR_AUTOSTART_TMUX_SESSION:-tkhq}"
readonly PERSONAL_TMUX_SESSION="${HYPR_AUTOSTART_PERSONAL_TMUX_SESSION:-personal}"

wait_for_hypr() {
  local runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  local signature="${HYPRLAND_INSTANCE_SIGNATURE:-}"

  if [[ -n "$signature" ]]; then
    local socket="$runtime/hypr/$signature/.socket.sock"
    for _ in {1..100}; do
      [[ -S "$socket" ]] && return 0
      sleep 0.1
    done
  fi

  command -v hyprctl >/dev/null 2>&1
}

wait_for_client() {
  local jq_filter="$1"

  for _ in {1..100}; do
    if hyprctl clients -j 2>/dev/null | jq -e "$jq_filter" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done

  return 1
}

client_address() {
  local jq_filter="$1"

  hyprctl clients -j 2>/dev/null \
    | jq -r "map(select(${jq_filter})) | last | .address // empty"
}

move_client_to_workspace() {
  local workspace="$1"
  local address="$2"

  [[ -n "$address" ]] || return 1
  hyprctl eval \
    "local w=hl.get_window(\"address:${address}\"); if w then hl.dispatch(hl.dsp.window.move({workspace=${workspace},window=w,follow=false})) end" \
    >/dev/null
}

focus_workspace() {
  local workspace="$1"
  hyprctl eval "hl.dispatch(hl.dsp.focus({workspace=${workspace}}))" >/dev/null
}

exec_on_workspace() {
  local workspace="$1"
  local command="$2"
  local lua_command

  lua_command="${command//\\/\\\\}"
  lua_command="${lua_command//\"/\\\"}"
  hyprctl eval \
    "hl.exec_cmd(\"${lua_command}\", {workspace=\"${workspace} silent\",no_initial_focus=true})" \
    >/dev/null
}

ensure_work_notes_window() {
  if ! tmux has-session -t "=${WORK_TMUX_SESSION}" 2>/dev/null; then
    tmux new-session -d -s "$WORK_TMUX_SESSION" -n Notes \
      -c "$HOME/notes" 'exec nvim .'
  elif ! tmux list-windows -t "=${WORK_TMUX_SESSION}" -F '#{window_name}' \
    | grep -Fxq Notes; then
    tmux new-window -d -t "${WORK_TMUX_SESSION}:" -n Notes \
      -c "$HOME/notes" 'exec nvim .'
  fi

  tmux set-option -w -t "${WORK_TMUX_SESSION}:Notes" automatic-rename off
  tmux select-window -t "${WORK_TMUX_SESSION}:Notes"
}

ensure_work_default_browser() {
  local mime_type

  xdg-settings set default-web-browser vivaldi-work.desktop
  for mime_type in \
    x-scheme-handler/http \
    x-scheme-handler/https \
    text/html; do
    xdg-mime default vivaldi-work.desktop "$mime_type"
  done
}

wait_for_hypr
[[ "$WORK_TMUX_SESSION" =~ ^[A-Za-z0-9_.-]+$ ]]
[[ "$PERSONAL_TMUX_SESSION" =~ ^[A-Za-z0-9_.-]+$ ]]
ensure_work_default_browser
ensure_work_notes_window

# A Vivaldi process can own windows from multiple profiles, while Hyprland
# exposes only the common process/class. Do not infer profile identity from
# launch timing, titles, or the workspace a window happens to occupy. Profile
# windows are intentionally left untouched here; vivaldi-work.desktop still
# makes the durable Default/Work profile the handler for normal web links.
focus_workspace "$WORKSPACE_WORK"
work_kitty_address="$(client_address '(.workspace.name == "10" and .class == "kitty-work")')"
if [[ -z "$work_kitty_address" ]]; then
  exec_on_workspace "$WORKSPACE_WORK" \
    "kitty --class kitty-work --title Notes -e tmux attach-session -t ${WORK_TMUX_SESSION}"
fi

work_kitty_filter='(.workspace.name == "10" and .class == "kitty-work")'
wait_for_client ".[] | select(${work_kitty_filter})" || true
focus_workspace "$WORKSPACE_PERSONAL"
personal_kitty_address="$(client_address '(.workspace.name == "8" and .class == "kitty-personal")')"
if [[ -z "$personal_kitty_address" ]]; then
  exec_on_workspace "$WORKSPACE_PERSONAL" \
    "kitty --class kitty-personal --title tmux-personal -e tmux new-session -A -s ${PERSONAL_TMUX_SESSION}"
fi

personal_kitty_filter='(.workspace.name == "8" and .class == "kitty-personal")'
wait_for_client ".[] | select(${personal_kitty_filter})" || true
slack_filter='(.class | test("^([Ss]lack|com.slack.Slack)$"))'
slack_address="$(client_address "$slack_filter")"
if [[ -z "$slack_address" ]]; then
  exec_on_workspace "$WORKSPACE_SLACK" "slack"
fi
wait_for_client ".[] | select(${slack_filter})" || true
slack_address="$(client_address "$slack_filter")"
move_client_to_workspace "$WORKSPACE_SLACK" "$slack_address" || true

focus_workspace "$WORKSPACE_WORK"
