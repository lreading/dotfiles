local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local work_laptop = io.open(config_home .. "/hypr/work_laptop.lua", "r")

if work_laptop then
  work_laptop:close()
  dofile(config_home .. "/hypr/lua/work_monitors.lua")
else
  hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.33 })
end
