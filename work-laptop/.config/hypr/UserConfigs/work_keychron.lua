-- Loaded only by the optional work-laptop package.
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local helpers = dofile(config_home .. "/hypr/lua/user_keybinds_helper.lua")
-- XKB maps the Q11 F13-F17 usages to these symbols.
local keys = { "XF86Tools", "XF86Launch5", "XF86Launch6", "XF86Launch7" }
local commands = { "restore", "brightness", "effect", "color" }
for index, command in ipairs(commands) do
  helpers.bind("", keys[index], helpers.exec_cmd("$HOME/.local/bin/work-keychron " .. command), {
    description = "Q11 M" .. index .. ": " .. command,
  })
  if index > 1 then
    helpers.bind("CTRL", keys[index], helpers.exec_cmd("$HOME/.local/bin/work-keychron " .. command .. " --reverse"), {
      description = "Q11 M" .. index .. ": reverse " .. command,
    })
  end
end
helpers.bind("", "XF86Launch8", helpers.exec_cmd("$HOME/.config/hypr/UserScripts/LockScreen.sh"), {
  description = "Q11 M5: lock screen",
})
