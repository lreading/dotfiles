-- Personal keybinds.  Upstream defaults load first, so remapped bindings are
-- explicitly unbound before their replacements are registered.
local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local helpers = dofile(config_home .. "/hypr/lua/user_keybinds_helper.lua")
local bind = helpers.bind
local unbind = helpers.unbind
local exec_cmd = helpers.exec_cmd
local dispatch = helpers.dispatch

bind("SUPER", "D", exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"))
bind("SUPER", "B", exec_cmd("xdg-open \"https://\""))
bind("SUPER", "E", exec_cmd("thunar"))

unbind("SUPER", "H")
unbind("SUPER SHIFT", "H")
bind("SUPER", "H", dispatch("movefocus", "l"))
bind("SUPER", "J", dispatch("movefocus", "d"))
bind("SUPER", "K", dispatch("movefocus", "u"))
bind("SUPER", "L", dispatch("movefocus", "r"))

bind("SUPER SHIFT", "H", exec_cmd("$HOME/.config/hypr/scripts/KeyHints.sh"))
bind("SUPER ALT", "R", exec_cmd("$HOME/.config/hypr/scripts/Refresh.sh"))
bind("SUPER ALT", "E", exec_cmd("$HOME/.config/hypr/scripts/RofiEmoji.sh"))
bind("SUPER", "S", exec_cmd("$HOME/.config/hypr/scripts/RofiSearch.sh"))
bind("SUPER ALT", "O", exec_cmd("$HOME/.config/hypr/scripts/ChangeBlur.sh"))
bind("SUPER SHIFT", "G", exec_cmd("$HOME/.config/hypr/scripts/GameMode.sh"))
bind("SUPER ALT", "L", exec_cmd("$HOME/.config/hypr/scripts/ChangeLayout.sh"))
bind("SUPER SHIFT", "L", exec_cmd("$HOME/.config/hypr/scripts/LockScreen.sh"))
bind("SUPER ALT", "V", exec_cmd("$HOME/.config/hypr/scripts/ClipManager.sh"))
bind("SUPER CTRL", "R", exec_cmd("$HOME/.config/hypr/scripts/RofiThemeSelector.sh"))
bind("SUPER CTRL SHIFT", "R", exec_cmd("pkill rofi || true && $HOME/.config/hypr/scripts/RofiThemeSelector-modified.sh"))

unbind("SUPER", "N")
bind("SUPER", "N", exec_cmd("swaync-client -t -sw"))

unbind("SUPER SHIFT", "F")
unbind("SUPER CTRL", "F")
unbind("SUPER", "F")
bind("SUPER SHIFT", "F", dispatch("fullscreen", "0"))
bind("SUPER CTRL", "F", dispatch("fullscreen", "1"))
bind("SUPER", "F", dispatch("fullscreen", "1"))
bind("SUPER", "SPACE", dispatch("togglefloating", ""))
bind("SUPER ALT", "SPACE", exec_cmd("hyprctl dispatch workspaceopt allfloat"))
bind("SUPER SHIFT", "Return", exec_cmd("$HOME/.config/hypr/scripts/Dropterminal.sh kitty"))

unbind("SUPER ALT", "mouse_down")
unbind("SUPER ALT", "mouse_up")
unbind("SUPER", "mouse_down")
unbind("SUPER", "mouse_up")

bind("SUPER CTRL ALT", "B", exec_cmd("pkill -SIGUSR1 waybar"))
bind("SUPER CTRL", "B", exec_cmd("$HOME/.config/hypr/scripts/WaybarStyles.sh"))
bind("SUPER ALT", "B", exec_cmd("$HOME/.config/hypr/scripts/WaybarLayout.sh"))
bind("SUPER SHIFT", "M", exec_cmd("$HOME/.config/hypr/UserScripts/RofiBeats.sh"))
bind("SUPER", "W", exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperSelect.sh"))
bind("SUPER SHIFT", "W", exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperEffects.sh"))
bind("CTRL ALT", "W", exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperRandom.sh"))
bind("SUPER CTRL", "O", exec_cmd("hyprctl setprop active opaque toggle"))
bind("SUPER SHIFT", "K", exec_cmd("$HOME/.config/hypr/scripts/KeyBinds.sh"))
bind("SUPER SHIFT", "A", exec_cmd("$HOME/.config/hypr/scripts/Animations.sh"))
bind("SUPER SHIFT", "O", exec_cmd("$HOME/.config/hypr/UserScripts/ZshChangeTheme.sh"))
bind("ALT_L", "SHIFT_L", exec_cmd("$HOME/.config/hypr/scripts/SwitchKeyboardLayout.sh"), { locked = true })
bind("SHIFT_L", "ALT_L", exec_cmd("$HOME/.config/hypr/scripts/Tak0-Per-Window-Switch.sh"), { locked = true })
bind("SUPER ALT", "C", exec_cmd("$HOME/.config/hypr/UserScripts/RofiCalc.sh"))
unbind("SUPER SHIFT", "S")
bind("SUPER SHIFT", "S", exec_cmd("$HOME/.config/hypr/UserScripts/ScreenShot.sh --swappy"))
