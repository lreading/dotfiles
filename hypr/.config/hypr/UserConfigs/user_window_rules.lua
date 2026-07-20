-- Personal application placement and display rules.
-- Keep session-started applications on their intended workspaces without
-- activating them. These rules also cover applications which fork after their
-- launcher exits (notably Portmaster and Chromium-based browsers).
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
  match = { class = "^portmaster$" },
  workspace = "8 silent",
  no_initial_focus = true,
})
hl.window_rule({ match = { class = "^([Dd]iscord|[Vv]esktop)$" }, workspace = 10 })
hl.window_rule({ match = { class = "^([Ss]lack|com.slack.Slack)$" }, workspace = 9 })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, workspace = "10 silent" })
-- Legacy `fullscreen 2` maps to the current internal/client fullscreen state.
-- Keep the client in fullscreen while Hyprland uses maximized mode, preserving
-- the Waybar-reserved area (the original user setting was `1 2`).
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, fullscreen_state = "1 2" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, tile = true })
