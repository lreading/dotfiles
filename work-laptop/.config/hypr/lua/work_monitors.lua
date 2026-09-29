local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local state = dofile(config_home .. "/hypr/lua/work_state.lua")

hl.monitor({ output = state.external, mode = "3840x1080@143.855", position = "0x0", scale = 1 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.33 })
