-- Generated from WindowRules.conf. Edit the matching Lua file going forward.
local H = require("lua.hypr_helpers")
hl.window_rule({ match = { class = H.expand("^([Vv]ivaldi(-stable)?)$") }, workspace = 2 })
hl.window_rule({ match = { class = H.expand("^([Dd]iscord|[Vv]esktop)$") }, workspace = 10 })
hl.window_rule({ match = { class = H.expand("^([Ss]lack|com.slack.Slack)$") }, workspace = 9 })
hl.window_rule({ match = { class = H.expand("^([Ff]erdium)$") }, workspace = 10 })
hl.window_rule({ match = { class = H.expand("^([Ff]erdium)$") }, fullscreen_state = "2 0" })
hl.window_rule({ match = { class = H.expand("^([Ff]erdium)$") }, tile = true })
