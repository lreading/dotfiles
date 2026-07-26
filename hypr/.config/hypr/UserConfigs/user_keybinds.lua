-- Personal keybinds.  Upstream defaults load first, so remapped bindings are
-- explicitly unbound before their replacements are registered.
local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local helpers = dofile(config_home .. "/hypr/lua/user_keybinds_helper.lua")
local bind = helpers.bind
local unbind = helpers.unbind
local exec_cmd = helpers.exec_cmd
local dispatch = helpers.dispatch
local raw_dispatch_cmd = helpers.raw_dispatch_cmd

local function rebind(mods, key, dispatcher, opts)
  unbind(mods, key)
  bind(mods, key, dispatcher, opts)
end

rebind("SUPER", "D", exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"), { description = "Application launcher" })
rebind("SUPER", "B", exec_cmd("xdg-open \"https://\""), { description = "Open default browser" })
rebind("SUPER", "E", exec_cmd("thunar"), { description = "Open file manager" })

rebind("SUPER", "H", dispatch("movefocus", "l"), { description = "Focus left (vim-style)" })
rebind("SUPER", "J", dispatch("movefocus", "d"), { description = "Focus down (vim-style)" })
rebind("SUPER", "K", dispatch("movefocus", "u"), { description = "Focus up (vim-style)" })
rebind("SUPER", "L", dispatch("movefocus", "r"), { description = "Focus right (vim-style)" })
rebind("ALT", "Tab", exec_cmd("$HOME/.config/hypr/UserScripts/CycleWindows.sh"), {
  description = "Cycle next window (all workspaces)",
})

-- Hyprland 0.55+ uses the Lua dispatcher API.  Its documented direction
-- values are the short forms l/r/u/d.
for _, direction in ipairs({
  { key = "left", value = "l" },
  { key = "right", value = "r" },
  { key = "up", value = "u" },
  { key = "down", value = "d" },
}) do
  unbind("SUPER CTRL", direction.key)
  bind(
    "SUPER CTRL",
    direction.key,
    hl.dsp.window.move({ direction = direction.value }),
    { description = "Move window " .. direction.key }
  )
end

rebind("SUPER SHIFT", "H", exec_cmd("$HOME/.config/hypr/UserScripts/KeyHints.sh"), { description = "Quick cheat sheet" })
rebind("SUPER ALT", "R", exec_cmd("$HOME/.config/hypr/scripts/Refresh.sh"), { description = "Refresh bar and menus" })
rebind("SUPER ALT", "E", exec_cmd("$HOME/.config/hypr/UserScripts/RofiEmoji.sh"), { description = "Emoji menu" })
rebind("SUPER", "S", exec_cmd("$HOME/.config/hypr/scripts/RofiSearch.sh"), { description = "Web search" })
rebind("SUPER ALT", "O", exec_cmd("$HOME/.config/hypr/scripts/ChangeBlur.sh"), { description = "Toggle blur" })
rebind("SUPER SHIFT", "G", exec_cmd("$HOME/.config/hypr/scripts/GameMode.sh"), { description = "Toggle game mode" })
rebind("SUPER ALT", "L", exec_cmd("$HOME/.config/hypr/scripts/ChangeLayout.sh toggle"), { description = "Toggle layouts" })

local lock_screen = exec_cmd("$HOME/.config/hypr/UserScripts/LockScreen.sh")
rebind("CTRL ALT", "L", lock_screen, { description = "Lock screen" })
rebind("SUPER SHIFT", "L", lock_screen, { description = "Lock screen" })

rebind("SUPER ALT", "V", exec_cmd("$HOME/.config/hypr/scripts/ClipManager.sh"), { description = "Clipboard manager" })
rebind("SUPER CTRL", "R", exec_cmd("$HOME/.config/hypr/scripts/RofiThemeSelector.sh"), { description = "Rofi theme selector" })
rebind("SUPER CTRL SHIFT", "R", exec_cmd("pkill rofi || true && $HOME/.config/hypr/scripts/RofiThemeSelector-modified.sh"), { description = "Rofi theme selector (modified)" })

rebind("SUPER", "N", exec_cmd("swaync-client -t -sw"), { description = "Notification panel" })

rebind("SUPER SHIFT", "F", dispatch("fullscreen", "0"), { description = "Fullscreen" })
rebind("SUPER CTRL", "F", dispatch("fullscreen", "1"), { description = "Fake fullscreen" })
rebind("SUPER", "F", dispatch("fullscreen", "1"), { description = "Fake fullscreen" })
rebind("SUPER", "SPACE", dispatch("togglefloating", ""), { description = "Float current window" })
rebind("SUPER ALT", "SPACE", exec_cmd("$HOME/.config/hypr/scripts/Float-all-Windows.sh"), { description = "Float all windows" })
rebind("SUPER SHIFT", "Return", exec_cmd("$HOME/.config/hypr/scripts/Dropterminal.sh kitty"), { description = "Drop-down terminal" })

unbind("SUPER ALT", "mouse_down")
unbind("SUPER ALT", "mouse_up")
unbind("SUPER", "mouse_down")
unbind("SUPER", "mouse_up")

rebind("SUPER CTRL ALT", "B", exec_cmd("pkill -SIGUSR1 waybar"), { description = "Toggle Waybar" })
rebind("SUPER CTRL", "B", exec_cmd("$HOME/.config/hypr/scripts/WaybarStyles.sh"), { description = "Waybar styles menu" })
rebind("SUPER ALT", "B", exec_cmd("$HOME/.config/hypr/scripts/WaybarLayout.sh"), { description = "Waybar layout menu" })
rebind("SUPER SHIFT", "M", exec_cmd("$HOME/.config/hypr/UserScripts/RofiBeats.sh"), { description = "Online music" })
rebind("SUPER", "W", exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperSelect.sh"), { description = "Select wallpaper" })
rebind("SUPER SHIFT", "W", exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperEffects.sh"), { description = "Wallpaper effects" })
rebind("CTRL ALT", "W", exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperRandom.sh"), { description = "Random wallpaper" })
rebind("SUPER CTRL", "O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }), { description = "Toggle active window opacity" })
rebind("SUPER SHIFT", "K", exec_cmd("$HOME/.config/hypr/UserScripts/KeyBinds.sh"), { description = "Search keybinds" })
rebind("SUPER SHIFT", "A", exec_cmd("$HOME/.config/hypr/scripts/Animations.sh"), { description = "Animations menu" })
rebind("SUPER SHIFT", "O", exec_cmd("$HOME/.config/hypr/UserScripts/ZshChangeTheme.sh"), { description = "Change ZSH theme" })
rebind("ALT_L", "SHIFT_L", exec_cmd("$HOME/.config/hypr/scripts/KeyboardLayout.sh switch"), { description = "Switch keyboard layout globally", locked = true })
rebind("SHIFT_L", "ALT_L", exec_cmd("$HOME/.config/hypr/scripts/Tak0-Per-Window-Switch.sh"), { description = "Switch keyboard layout per-window", locked = true })
rebind("SUPER ALT", "C", exec_cmd("$HOME/.config/hypr/UserScripts/RofiCalc.sh"), { description = "Calculator" })
rebind("SUPER SHIFT", "S", exec_cmd("$HOME/.config/hypr/UserScripts/ScreenShot.sh --swappy"), { description = "Screenshot (swappy)" })

-- The installed vendor binding predates the Lua dispatcher CLI.  Match the
-- implementation used by the latest upstream keybinds instead.
rebind("SUPER", "M", raw_dispatch_cmd("splitratio 0.3"), { description = "Set split ratio 0.3" })

-- Avoid two upstream duplicate-bind bugs.  XF86AudioPlay otherwise toggles
-- playback twice, while SUPER CTRL K runs two unrelated actions at once.
rebind("", "XF86AudioPlay", exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --pause"), {
  description = "Play/pause",
  locked = true,
})
rebind("SUPER CTRL", "K", hl.dsp.window.move({ into_group = "left" }), { description = "Move left into group" })
rebind("SUPER CTRL SHIFT", "K", exec_cmd("$HOME/.config/hypr/scripts/Kitty_themes.sh"), {
  description = "Kitty theme selector",
})
