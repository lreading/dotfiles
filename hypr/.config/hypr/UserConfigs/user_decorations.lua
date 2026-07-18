-- Personal visual settings, retaining Wallust-driven border colors.
local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local helpers = dofile(config_home .. "/hypr/lua/user_decorations_helper.lua")
local colors = helpers.load_wallust_colors(config_home .. "/hypr/wallust/wallust-hyprland.conf")
local function color(name, fallback)
  return colors[name] or fallback
end

hl.config({
  general = {
    border_size = 2, gaps_in = 2, gaps_out = 4,
    col = {
      active_border = color("color12", "rgba(8db4ffff)"),
      inactive_border = color("color10", "rgba(5f6578ff)"),
    },
  },
  decoration = {
    rounding = 10, active_opacity = 1.0, inactive_opacity = 0.9,
    fullscreen_opacity = 1.0, dim_inactive = true, dim_strength = 0.1,
    dim_special = 0.8,
    shadow = {
      enabled = true, range = 2, render_power = 1,
      color = color("color12", "rgba(8db4ffff)"),
      color_inactive = color("color10", "rgba(5f6578ff)"),
    },
    blur = {
      enabled = true, size = 6, passes = 2, ignore_opacity = true,
      new_optimizations = true, special = true, popups = true,
    },
  },
  group = {
    col = { border_active = color("color15", "rgba(ffffffff)") },
    groupbar = { col = { active = color("color0", "rgba(0f111aff)") } },
  },
})
