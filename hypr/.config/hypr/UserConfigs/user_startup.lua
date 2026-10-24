local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local startup = dofile(config_home .. "/hypr/UserConfigs/startup_log.lua")
local work_laptop = config_home .. "/hypr/work_laptop.lua"
local work_file = io.open(work_laptop, "r")
local monitor_overrides = config_home .. "/hypr/UserConfigs/monitors.lua"

-- hyprland.lua loads the vendor monitor defaults after the user split files.
-- Re-apply the Stow-managed monitor profile after that load so it wins on both
-- startup and config reload. monitors.lua selects the work profile when its
-- optional work-laptop package is installed.
local function apply_monitor_overrides()
  startup.run("monitor overrides", function()
    dofile(monitor_overrides)
  end)
end

hl.on("config.reloaded", apply_monitor_overrides)
hl.on("hyprland.start", apply_monitor_overrides)

if work_file then
  work_file:close()
  startup.include(work_laptop)
else
  hl.on("hyprland.start", function()
    startup.launch("kitty-tmux", "kitty --class hypr-startup-kitty --name hypr-startup-tmux -T hypr-startup-tmux -e tmux new-session -n TODO 'nvim TODO.md' \\; new-window \\; select-window -t :TODO")
    startup.run("zen", function()
      -- Launch directly so placement tracks Zen's PID, not the logging wrapper.
      hl.exec_cmd("exec zen-browser", { workspace = "2 silent", no_initial_focus = true })
    end)
  end)
end
