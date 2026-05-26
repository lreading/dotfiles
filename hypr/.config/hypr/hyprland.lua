-- Hyprland 0.55+ Lua entrypoint.
-- Legacy hyprland.conf is kept as a fallback only; Hyprland prefers this file at startup.
local H = require("lua.hypr_helpers")

H.set("configs", "$HOME/.config/hypr/configs")
H.set("UserConfigs", "$HOME/.config/hypr/UserConfigs")
H.load_vars("$HOME/.config/hypr/wallust/wallust-hyprland.conf")

H.exec_once("$HOME/.config/hypr/initial-boot.sh")

require("configs.Keybinds")
require("configs.Startup_Apps")
require("UserConfigs.Startup_Apps")

require("configs.ENVariables")
require("UserConfigs.ENVariables")

require("configs.Laptops")
require("UserConfigs.Laptops")
require("UserConfigs.LaptopDisplay")

require("configs.WindowRules")
require("UserConfigs.WindowRules")

require("configs.SystemSettings")
require("UserConfigs.UserDecorations")
require("UserConfigs.UserAnimations")
require("UserConfigs.UserKeybinds")
require("UserConfigs.UserSettings")
require("UserConfigs.01-UserDefaults")

require("monitors")
require("workspaces")
