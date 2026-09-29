local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local startup = dofile(config_home .. "/hypr/UserConfigs/startup_log.lua")
startup.include(config_home .. "/hypr/lua/work_window_rules.lua")
local session_ok, session = pcall(dofile, config_home .. "/hypr/lua/work_session.lua")
if not session_ok then startup.note("FAILED to load work session: " .. tostring(session)) end

local function apply_workspaces()
  startup.run("work workspace rules", function()
    dofile(config_home .. "/hypr/lua/work_workspaces.lua")
  end)
end

hl.on("config.reloaded", apply_workspaces)

hl.on("hyprland.start", function()
  apply_workspaces()
  startup.launch("dock-watcher", "$HOME/.local/bin/work-laptop-dockd")
  startup.launch("network-watcher", "$HOME/.local/bin/work-laptop-netd")
  if session_ok then startup.run("work session", session.start) end
end)
