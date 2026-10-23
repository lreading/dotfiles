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
    match = { class = "^zen$" },
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
    workspace = "10 silent",
    no_initial_focus = true,
  })
  hl.window_rule({ match = { class = "^([Dd]iscord|[Vv]esktop)$" }, workspace = 10 })
end

if not is_work_laptop then
  hl.window_rule({ match = { class = "^([Ss]lack|com.slack.Slack)$" }, workspace = "9 silent" })
end

-- Threat Dragon's Linux desktop/E2E executable uses `threat-dragon`; match the
-- packaged app ID too so test windows stay off the active workspace.
hl.window_rule({
  match = { class = "^(threat-dragon|org\\.owasp\\.threatdragon)$" },
  workspace = "6 silent",
  no_initial_focus = true,
})
