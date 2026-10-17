local function quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local logger = config_home .. "/hypr/UserScripts/LogStartup.sh"
local logger_ok

local function note(message)
  pcall(hl.exec_cmd, "systemd-cat --identifier=hypr-user-startup --priority=info -- echo " .. quote(message))
end

local function has_logger()
  if logger_ok == nil then
    local file = io.open(logger, "r")
    logger_ok = file ~= nil
    if file then file:close() end
  end
  return logger_ok
end

local function fail(message)
  note(message)
  if has_logger() then
    pcall(hl.exec_cmd, quote(logger) .. " --failure " .. quote(message))
  else
    pcall(hl.exec_cmd, "hyprctl seterror 'rgba(ff5555ff)' " .. quote(message))
  end
end

local function launch(label, command)
  if not has_logger() then
    fail("Startup failed: missing logger " .. logger)
    return
  end

  local run = "systemd-cat --identifier=hypr-user-startup --priority=info -- "
    .. quote(logger) .. " " .. quote(label) .. " sh -lc " .. quote(command)
  local ok, err = pcall(hl.exec_cmd, run)
  if not ok then fail("FAILED to queue " .. label .. ": " .. tostring(err)) end
end

local function include(path)
  local ok, err = pcall(dofile, path)
  if not ok then fail("FAILED to load " .. path .. ": " .. tostring(err)) end
end

local function run(label, action)
  local ok, err = pcall(action)
  if not ok then fail("FAILED " .. label .. ": " .. tostring(err)) end
end

return { launch = launch, note = note, include = include, run = run }
