-- Shared helpers for the Hyprland 0.55 Lua migration.
local M = {}

M.vars = {
  HOME = os.getenv("HOME") or "",
  USER = os.getenv("USER") or "",
}

function M.set(name, value)
  M.vars[name] = M.expand(value)
end

function M.var(name)
  return M.vars[name] or os.getenv(name) or ""
end

function M.expand(value)
  if type(value) ~= "string" then
    return value
  end
  local expanded = value:gsub("%${([%w_]+):%-([^}]-)}", function(name, fallback)
    local env = os.getenv(name)
    if env == nil or env == "" then
      return fallback
    end
    return env
  end)
  expanded = expanded:gsub("%$([%a_][%w_]*)", function(name)
    return M.var(name)
  end)
  return expanded
end

function M.load_vars(path)
  local file = io.open(M.expand(path), "r")
  if not file then
    return
  end
  for line in file:lines() do
    local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
    if name and value then
      M.vars[name] = M.expand(value)
    end
  end
  file:close()
end

local function exec_parts(command)
  local rule, cmd = command:match("^%s*%[(.-)%]%s*(.+)$")
  if not rule then
    return command, nil
  end
  local kind, rest = rule:match("^(%S+)%s+(.+)$")
  if not kind then
    return cmd, nil
  end
  return cmd, { [kind] = rest }
end

function M.exec_once(command)
  command = M.expand(command)
  hl.on("hyprland.start", function()
    local cmd, rules = exec_parts(command)
    hl.exec_cmd(cmd, rules)
  end)
end

function M.bind(keys, dispatcher, params, opts)
  keys = M.expand(keys)
  params = M.expand(params or "")
  opts = opts or {}
  if dispatcher == "exec" then
    hl.bind(keys, hl.dsp.exec_cmd(params), opts)
  elseif dispatcher == "global" then
    hl.bind(keys, hl.dsp.global(params), opts)
  else
    hl.bind(keys, function()
      local cmd = "hyprctl dispatch " .. dispatcher
      if params ~= "" then
        cmd = cmd .. " " .. params
      end
      hl.exec_cmd(cmd)
    end, opts)
  end
end

return M
