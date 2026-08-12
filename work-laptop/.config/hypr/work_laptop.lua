-- Work-laptop-only monitor, workspace, and background-service settings.
local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local startup = dofile(config_home .. "/hypr/lua/user_startup_helper.lua")
local external_monitor = "desc:ASUSTek COMPUTER INC ASUS XG49V 0x00020793"

-- The work-laptop autostart helper owns application placement. An empty table
-- suppresses the personal laptop's workspace 1/2 startup windows.
KOOLDOTS_SESSION_WINDOWS = {}
KOOLDOTS_USER_STARTUP_COMMANDS = {
  "$HOME/.config/hypr/UserScripts/RainbowBorders.sh",
  "$HOME/.config/hypr/UserScripts/ApplyUserPreferences.sh",
  "$HOME/.config/hypr/UserScripts/StartHypridle.sh",
}

local function apply_display_profile()
  hl.monitor({
    output = external_monitor,
    mode = "3840x1080@143.855",
    position = "0x0",
    scale = 1,
  })
  for workspace = 1, 10 do
    hl.workspace_rule({
      workspace = tostring(workspace),
      monitor = external_monitor,
      default = workspace == 1,
    })
  end
  hl.workspace_rule({ workspace = "special:scratchpad", monitor = external_monitor })
end

local function start_services()
  startup.exec_once("$HOME/.local/bin/work-laptop-dockd")
  startup.exec_once("$HOME/.local/bin/work-laptop-netd")
  startup.exec_once("$HOME/.config/hypr/UserScripts/AutostartApps.sh")
end

apply_display_profile()

if hl and hl.on then
  hl.on("config.reloaded", apply_display_profile)
  hl.on("hyprland.start", function()
    apply_display_profile()
    start_services()
  end)
else
  start_services()
end
