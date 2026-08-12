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
  "$HOME/.config/hypr/UserScripts/StartHypridle.sh",
  "ferdium --force-device-scale-factor=1.2",
  "gnome-keyring-daemon --start --components=secrets",
}
local function run_startup_commands()
  local commands = rawget(_G, "KOOLDOTS_USER_STARTUP_COMMANDS") or startup_commands
  for _, cmd in ipairs(commands) do exec_once(cmd) end
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

  if hl and hl.exec_cmd then
    -- `hl.exec_cmd` is the Lua API which accepts per-launch window rules.
    -- The dispatcher variant only accepts the command, so its second argument
    -- was ignored after the Hyprland Lua migration.
    hl.exec_cmd(command, rules)
  else
    exec_once(command)
  end
end

local default_session_windows = {
  {
    id = "kitty-tmux",
    command = "kitty --class hypr-startup-kitty --name hypr-startup-tmux -T hypr-startup-tmux -e tmux new-session -n TODO 'nvim TODO.md' \\; new-window \\; select-window -t :TODO",
    rules = { workspace = "1 silent", no_initial_focus = true },
  },
  {
    id = "vivaldi",
    command = "vivaldi",
    rules = { workspace = "2 silent", no_initial_focus = true },
  },
}

local function launch_session_windows()
  local windows = rawget(_G, "KOOLDOTS_SESSION_WINDOWS") or default_session_windows
  for _, window in ipairs(windows) do
    launch_window_once(window.id, window.command, window.rules)
  end
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
  local installed = os.execute("command -v portmaster >/dev/null 2>&1")
  if installed == true or installed == 0 then
    exec_once("portmaster --with-prompts --with-notifications")
  end
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

-- Machine-specific packages can provide an optional module without making
-- the shared Hyprland configuration depend on that machine.
do
  local work_laptop = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config"))
    .. "/hypr/work_laptop.lua"
  local handle = io.open(work_laptop, "r")
  if handle then
    handle:close()
    local ok, err = pcall(dofile, work_laptop)
    if not ok then print("Failed to load work laptop settings: " .. tostring(err)) end
  end
end
