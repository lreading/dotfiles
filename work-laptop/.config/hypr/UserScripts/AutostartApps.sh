#!/usr/bin/env bash
set -euo pipefail

readonly EXTERNAL_DESC="ASUSTek COMPUTER INC ASUS XG49V 0x00020793"
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

external_connected() {
  hyprctl monitors all -j 2>/dev/null \
    | jq -e --arg desc "$EXTERNAL_DESC" \
      '.[] | select(.description == $desc and (.disabled | not))' \
      >/dev/null
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

vivaldi_addresses() {
  hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select((.class // "") | test("^[Vv]ivaldi(-stable)?$")) | .address'
}

wait_for_vivaldi_count() {
  local minimum="$1"
  local count

  for _ in {1..300}; do
    count="$(vivaldi_addresses | wc -l)"
    ((count >= minimum)) && return 0
    sleep 0.1
  done

  return 1
}

client_x() {
  local address="$1"

  hyprctl clients -j 2>/dev/null | jq -r --arg address "$address" '
    .[] | select(.address == $address) | .at[0] // empty
  '
}

ensure_left_of() {
  local left_address="$1"
  local right_address="$2"
  local left_x right_x

  [[ -n "$left_address" && -n "$right_address" ]] || return 0
  left_x="$(client_x "$left_address")"
  right_x="$(client_x "$right_address")"
  [[ -n "$left_x" && -n "$right_x" ]] || return 0

  if ((left_x > right_x)); then
    hyprctl eval \
      "local w=hl.get_window(\"address:${left_address}\"); if w then hl.dispatch(hl.dsp.focus({window=w})); hl.dispatch(hl.dsp.window.swap({direction=\"left\"})) end" \
      >/dev/null
  fi
}

launch_vivaldi_profiles() {
  local work_address personal_address address
  local -a existing=() work_windows=() personal_windows=()
  local -A before_personal=()

  mapfile -t existing < <(vivaldi_addresses)

  # Never classify or move browsers that predate this helper. At a normal work
  # login there are none: personal-laptop Vivaldi startup is disabled by
  # work_laptop.lua. Starting from zero lets each explicit profile launch be
  # attributed without using page titles or racing concurrent windows.
  ((${#existing[@]} == 0)) || return 0

  focus_workspace "$WORKSPACE_WORK_BROWSER"
  /usr/bin/vivaldi-stable --profile-directory=Default \
    >/tmp/vivaldi-work-autostart.log 2>&1 &
  wait_for_vivaldi_count 1 || return 1
  mapfile -t work_windows < <(vivaldi_addresses)
  work_address="${work_windows[0]:-}"

  for address in "${work_windows[@]}"; do
    before_personal["$address"]=1
  done

  # Vivaldi routes subsequent profile requests through its existing browser
  # process. Make the selected personal-browser workspace active while Profile
  # 1 creates/restores its own window, then identify only new addresses.
  focus_workspace "$WORKSPACE_PERSONAL_BROWSER"
  /usr/bin/vivaldi-stable --profile-directory='Profile 1' --new-window \
    >/tmp/vivaldi-personal-autostart.log 2>&1 &

  for _ in {1..300}; do
    mapfile -t personal_windows < <(
      vivaldi_addresses | while IFS= read -r address; do
        [[ -z "${before_personal[$address]:-}" ]] && printf '%s\n' "$address"
      done
    )
    ((${#personal_windows[@]} > 0)) && break
    sleep 0.1
  done
  personal_address="${personal_windows[0]:-}"

  if [[ "$DISPLAY_PROFILE" == "desktop" ]]; then
    ensure_left_of "$work_address" "$work_kitty_address"
    ensure_left_of "$personal_address" "$personal_kitty_address"
  fi
}

ensure_work_notes_window() {
  if ! tmux has-session -t "=${WORK_TMUX_SESSION}" 2>/dev/null; then
    tmux new-session -d -s "$WORK_TMUX_SESSION" -n notes \
      -c "$HOME" "cd \"$HOME/notes\" && exec nvim ."
  elif ! tmux list-windows -t "=${WORK_TMUX_SESSION}" -F '#{window_name}' \
    | grep -Fxq notes; then
    tmux new-window -d -t "${WORK_TMUX_SESSION}:" -n notes \
      -c "$HOME/notes" 'exec nvim .'
  fi

  tmux set-option -w -t "${WORK_TMUX_SESSION}:notes" automatic-rename off
  tmux select-window -t "${WORK_TMUX_SESSION}:notes"
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

if external_connected; then
  # Preserve the existing external-display layout exactly.
  readonly DISPLAY_PROFILE=desktop
  readonly WORKSPACE_WORK=10
  readonly WORKSPACE_WORK_BROWSER=10
  readonly WORKSPACE_PERSONAL_BROWSER=8
  readonly WORKSPACE_PERSONAL=8
  readonly WORKSPACE_SLACK=9
else
  readonly DISPLAY_PROFILE=laptop
  readonly WORKSPACE_WORK=1
  readonly WORKSPACE_WORK_BROWSER=2
  readonly WORKSPACE_PERSONAL_BROWSER=4
  readonly WORKSPACE_PERSONAL=5
  readonly WORKSPACE_SLACK=10
fi

ensure_work_default_browser
ensure_work_notes_window

# A Vivaldi process can own windows from multiple profiles, while Hyprland
# exposes only the common process/class. Existing windows are left untouched;
# only windows from a clean, sequential profile launch are attributed. The
# vivaldi-work.desktop handler keeps normal web links on Default/Work.
focus_workspace "$WORKSPACE_WORK"
work_kitty_address="$(client_address "(.workspace.name == \"${WORKSPACE_WORK}\" and .class == \"kitty-work\")")"
if [[ -z "$work_kitty_address" ]]; then
  exec_on_workspace "$WORKSPACE_WORK" \
    "kitty --class kitty-work --title notes -e tmux attach-session -t ${WORK_TMUX_SESSION}"
fi

work_kitty_filter="(.workspace.name == \"${WORKSPACE_WORK}\" and .class == \"kitty-work\")"
wait_for_client ".[] | select(${work_kitty_filter})" || true
work_kitty_address="$(client_address "$work_kitty_filter")"
focus_workspace "$WORKSPACE_PERSONAL"
personal_kitty_address="$(client_address "(.workspace.name == \"${WORKSPACE_PERSONAL}\" and .class == \"kitty-personal\")")"
if [[ -z "$personal_kitty_address" ]]; then
  exec_on_workspace "$WORKSPACE_PERSONAL" \
    "kitty --class kitty-personal --title tmux-personal -e tmux new-session -A -s ${PERSONAL_TMUX_SESSION}"
fi

personal_kitty_filter="(.workspace.name == \"${WORKSPACE_PERSONAL}\" and .class == \"kitty-personal\")"
wait_for_client ".[] | select(${personal_kitty_filter})" || true
personal_kitty_address="$(client_address "$personal_kitty_filter")"

launch_vivaldi_profiles || true

slack_filter='(.class | test("^([Ss]lack|com.slack.Slack)$"))'
slack_address="$(client_address "$slack_filter")"
if [[ -z "$slack_address" ]]; then
  exec_on_workspace "$WORKSPACE_SLACK" "slack"
fi
wait_for_client ".[] | select(${slack_filter})" || true
slack_address="$(client_address "$slack_filter")"
move_client_to_workspace "$WORKSPACE_SLACK" "$slack_address" || true

focus_workspace "$WORKSPACE_WORK"
