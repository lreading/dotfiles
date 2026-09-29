local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local state = dofile(config_home .. "/hypr/lua/work_state.lua")

if state.desktop() then
  hl.config({ master = { mfact = 0.5, new_status = "slave" } })
  for number = 1, 10 do
    local rule = {
      workspace = tostring(number),
      monitor = state.external,
      default = number == 1,
    }
    if number == 8 or number == 10 then rule.layout = "master" end
    hl.workspace_rule(rule)
  end
  hl.workspace_rule({ workspace = "special:scratchpad", monitor = state.external })
end
