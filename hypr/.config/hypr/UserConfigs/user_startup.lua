-- Personal startup commands, separate from vendor startup defaults.
local session = os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "default"
local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end
local function exec_once(cmd)
  local key = cmd:gsub("[^%w_.-]", "_"):sub(1, 80)
  local marker = "/tmp/hypr-lua-user-exec-once-" .. session .. "-" .. key
  local log = "/tmp/hypr-lua-user-startup-" .. key .. ".log"
  local script = "[ -e " .. shell_quote(marker) .. " ] || { touch " .. shell_quote(marker)
    .. " && sh -lc " .. shell_quote(cmd) .. " >>" .. shell_quote(log) .. " 2>&1 & }"
  os.execute("sh -lc " .. shell_quote(script))
end

local startup_commands = {
  "$HOME/.config/hypr/UserScripts/RainbowBorders.sh",
  "$HOME/.config/hypr/UserScripts/ApplyUserPreferences.sh",
  "sh -c 'sleep 2; pkill -x hypridle; setsid hypridle -c \"$HOME/.config/hypr/UserConfigs/hypridle.conf\" >/tmp/hypridle-user.log 2>&1 &'",
  "ferdium --force-device-scale-factor=1.2",
  "gnome-keyring-daemon --start --components=secrets",
}
local function run_startup_commands()
  for _, cmd in ipairs(startup_commands) do exec_once(cmd) end
end

-- Hyprlang's `[workspace N silent] command` prefix is not shell syntax. The
-- old startup wrapper executed it with `sh -lc`, which is why Kitty and
-- Vivaldi failed to start. Use the Lua dispatcher and a per-session marker.
local function launch_window_once(id, command, rules)
  local marker = "/tmp/hypr-lua-user-window-" .. session .. "-" .. id
  local marker_file = io.open(marker, "r")
  if marker_file then
    marker_file:close()
    return
  end

  marker_file = io.open(marker, "w")
  if marker_file then marker_file:close() end

  if hl and hl.dsp and hl.dsp.exec_cmd then
    hl.dispatch(hl.dsp.exec_cmd(command, rules))
  else
    exec_once(command)
  end
end

local function launch_session_windows()
  launch_window_once("kitty-tmux", "kitty --class hypr-startup-kitty -e tmux new", {
    workspace = "1 silent",
    no_initial_focus = true,
  })
  launch_window_once("vivaldi", "vivaldi", {
    workspace = "2 silent",
    no_initial_focus = true,
  })
end

-- The vendor monitor module is loaded after the UserConfigs modules. Apply
-- our monitor file once configuration is fully loaded, and after each reload,
-- so its scale cannot be reset to the vendor default of 1.0.
local function apply_user_monitors()
  local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  local ok, err = pcall(dofile, config_home .. "/hypr/UserConfigs/monitors.lua")
  if not ok then print("Failed to apply user monitor settings: " .. tostring(err)) end
end

-- Portmaster's launcher forks, so its workspace/focus behavior is defined by
-- the class rule in user_window_rules.lua rather than PID-bound exec rules.
local function launch_portmaster_once()
  exec_once("portmaster --with-prompts --with-notifications")
end

if hl and hl.on then
  hl.on("config.reloaded", apply_user_monitors)
  hl.on("hyprland.start", function()
    apply_user_monitors()
    run_startup_commands()
    launch_session_windows()
    launch_portmaster_once()
  end)
else
  apply_user_monitors()
  run_startup_commands()
  launch_session_windows()
  launch_portmaster_once()
end
