-- Personal application placement and display rules.
hl.window_rule({ match = { class = "^([Vv]ivaldi(-stable)?)$" }, workspace = 2 })
hl.window_rule({ match = { class = "^([Dd]iscord|[Vv]esktop)$" }, workspace = 10 })
hl.window_rule({ match = { class = "^([Ss]lack|com.slack.Slack)$" }, workspace = 9 })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, workspace = "10 silent" })
-- Legacy `fullscreen 2` maps to the current internal/client fullscreen state.
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, fullscreen_state = "2 2" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, tile = true })
