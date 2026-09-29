local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local state = dofile(config_home .. "/hypr/lua/work_state.lua")
local docked = state.desktop()
local function workspace(number) return tostring(number) .. " silent" end

hl.window_rule({ match = { class = "^[Ss]lack$" }, workspace = workspace(docked and 9 or 10), no_initial_focus = true })
hl.window_rule({ match = { class = "^vivaldi-stable$" }, no_initial_focus = true })

for _, window in ipairs({
  { class = "kitty-work", title = "notes", workspace = docked and 10 or 1 },
  { class = "kitty-personal", title = "tmux-personal", workspace = docked and 8 or 5 },
}) do
  for field, value in pairs({ class = window.class, initial_title = window.title }) do
    hl.window_rule({ match = { [field] = "^" .. value .. "$" }, workspace = workspace(window.workspace), no_initial_focus = true })
  end
end
