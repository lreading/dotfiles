-- Generated from UserDecorations.conf. Edit the matching Lua file going forward.
local H = require("lua.hypr_helpers")
hl.config({ general = { border_size = 2, gaps_in = 2, gaps_out = 4, col = { active_border = H.var("color12"), inactive_border = H.var("color10") } } })
hl.config({ decoration = { rounding = 10, active_opacity = 1.0, inactive_opacity = 0.9, fullscreen_opacity = 1.0, dim_inactive = true, dim_strength = 0.1, dim_special = 0.8, shadow = { enabled = true, range = 3, render_power = 1, color = H.var("color12"), color_inactive = H.var("color10") }, blur = { enabled = true, size = 6, passes = 2, ignore_opacity = true, new_optimizations = true, special = true, popups = true } } })
hl.config({ group = { col = { border_active = H.var("color15") }, groupbar = { col = { active = H.var("color0") } } } })
