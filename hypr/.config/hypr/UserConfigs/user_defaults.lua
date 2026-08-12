-- Personal application defaults for the KoolDots Lua workflow.
KOOLDOTS_DEFAULTS = KOOLDOTS_DEFAULTS or {}
KOOLDOTS_DEFAULTS.edit = "nvim"
KOOLDOTS_DEFAULTS.visual = "nvim"
KOOLDOTS_DEFAULTS.term = "kitty"
KOOLDOTS_DEFAULTS.files = "thunar"
KOOLDOTS_DEFAULTS.search_engine = "https://www.google.com/search?q={}"
KOOLDOTS_DEFAULTS.Search_Engine = KOOLDOTS_DEFAULTS.search_engine

-- Upstream's Lua entrypoint normally loads generated system_*.lua files from
-- ~/.config/hypr/configs. Older installations upgraded in place may have the
-- base Lua modules but not those generated split files. Without this fallback,
-- all vendor startup commands and the base keymap silently disappear.
do
  local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
  local hypr_dir = config_home .. "/hypr"
  local generated_startup = io.open(hypr_dir .. "/configs/system_startup.lua", "r")

  if generated_startup then
    generated_startup:close()
  else
    for _, module in ipairs({
      "env",
      "startup",
      "window_rules",
      "layer_rules",
      "keybinds",
      "settings",
      "laptops",
    }) do
      dofile(hypr_dir .. "/lua/" .. module .. ".lua")
    end
  end
end
