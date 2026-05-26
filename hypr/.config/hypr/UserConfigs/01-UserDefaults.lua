-- Generated from 01-UserDefaults.conf. Edit the matching Lua file going forward.
local H = require("lua.hypr_helpers")
hl.env(H.expand("EDITOR"), H.expand("nvim"))
H.set("edit", H.expand("${EDITOR:-nano}"))
H.set("term", H.expand("kitty"))
H.set("files", H.expand("thunar"))
H.set("Search_Engine", H.expand("\"https://www.google.com/search?q={}\""))
