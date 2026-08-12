-- Personal-laptop application placement. On the work laptop, Vivaldi profile
-- windows are deliberately not matched or moved because they share a class.
local work_laptop_file = io.open(
  (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config"))
    .. "/hypr/work_laptop.lua",
  "r"
)
local is_work_laptop = work_laptop_file ~= nil
if work_laptop_file then work_laptop_file:close() end

if not is_work_laptop then
  hl.window_rule({
    match = { class = "^([Vv]ivaldi(-stable)?)$" },
    workspace = "2 silent",
    no_initial_focus = true,
  })
  hl.window_rule({
    match = { class = "^hypr-startup-kitty$" },
    workspace = "1 silent",
    no_initial_focus = true,
  })
  hl.window_rule({
    -- Kitty exposes the requested class only after the initial Wayland
    -- surface is mapped. Match the stable initial title for startup placement.
    match = { initial_title = "^hypr-startup-tmux$" },
    workspace = "1 silent",
    no_initial_focus = true,
  })
  hl.window_rule({
    match = { class = "^portmaster$" },
    workspace = "8 silent",
    no_initial_focus = true,
  })
  hl.window_rule({ match = { class = "^([Dd]iscord|[Vv]esktop)$" }, workspace = 10 })
  hl.window_rule({ match = { class = "^([Ff]erdium)$" }, workspace = "10 silent" })
  -- Legacy `fullscreen 2` maps to the current internal/client fullscreen state.
  -- Keep the client in fullscreen while Hyprland uses maximized mode, preserving
  -- the Waybar-reserved area (the original user setting was `1 2`).
  hl.window_rule({ match = { class = "^([Ff]erdium)$" }, fullscreen_state = "1 2" })
  hl.window_rule({ match = { class = "^([Ff]erdium)$" }, tile = true })
end

hl.window_rule({ match = { class = "^([Ss]lack|com.slack.Slack)$" }, workspace = "9 silent" })
