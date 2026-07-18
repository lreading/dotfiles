-- Personal laptop hardware bindings and input-device settings.
local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local helpers = dofile(config_home .. "/hypr/lua/user_keybinds_helper.lua")
local bind = helpers.bind
local exec_cmd = helpers.exec_cmd
local scripts = "$HOME/.config/hypr/scripts/"

bind("", "XF86KbdBrightnessDown", exec_cmd(scripts .. "BrightnessKbd.sh --dec"), { repeating = true })
bind("", "XF86KbdBrightnessUp", exec_cmd(scripts .. "BrightnessKbd.sh --inc"), { repeating = true })
bind("", "XF86Launch1", exec_cmd("rog-control-center"))
bind("", "XF86Launch3", exec_cmd("asusctl led-mode -n"))
bind("", "XF86Launch4", exec_cmd("asusctl profile -n"))
bind("", "XF86MonBrightnessDown", exec_cmd(scripts .. "Brightness.sh --dec"), { repeating = true })
bind("", "XF86MonBrightnessUp", exec_cmd(scripts .. "Brightness.sh --inc"), { repeating = true })
bind("", "XF86TouchpadToggle", exec_cmd(scripts .. "TouchPad.sh"))
bind("SUPER", "F6", exec_cmd(scripts .. "ScreenShot.sh --now"))
bind("SUPER SHIFT", "F6", exec_cmd(scripts .. "ScreenShot.sh --area"))
bind("SUPER CTRL", "F6", exec_cmd(scripts .. "ScreenShot.sh --in5"))
bind("SUPER ALT", "F6", exec_cmd(scripts .. "ScreenShot.sh --in10"))
bind("ALT", "F6", exec_cmd(scripts .. "ScreenShot.sh --active"))

hl.device({ name = "asue1209:00-04f3:319f-touchpad", enabled = true })
