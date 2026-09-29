local function quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local logger = "$HOME/.config/hypr/UserScripts/LogStartup.sh"

local function note(message)
  os.execute("systemd-cat --identifier=hypr-user-startup --priority=info -- echo " .. quote(message))
end

local function launch(label, command)
  local run = "systemd-cat --identifier=hypr-user-startup --priority=info -- "
    .. logger .. " " .. quote(label) .. " sh -lc " .. quote(command)
  local ok, err = pcall(hl.exec_cmd, run)
  if not ok then note("FAILED to queue " .. label .. ": " .. tostring(err)) end
end

local function include(path)
  local ok, err = pcall(dofile, path)
  if not ok then note("FAILED to load " .. path .. ": " .. tostring(err)) end
end

local function run(label, action)
  local ok, err = pcall(action)
  if not ok then note("FAILED " .. label .. ": " .. tostring(err)) end
end

return { launch = launch, note = note, include = include, run = run }
