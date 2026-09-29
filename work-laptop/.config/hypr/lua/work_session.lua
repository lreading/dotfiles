local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local startup = dofile(config_home .. "/hypr/UserConfigs/startup_log.lua")
local state = dofile(config_home .. "/hypr/lua/work_state.lua")

local stage
local workspaces

local function place(window, workspace)
  if window.workspace and window.workspace.name == tostring(workspace) then return end
  hl.dispatch(hl.dsp.window.move({ window = window, workspace = workspace, follow = false }))
end

local function kitty(kind)
  startup.launch("kitty-" .. kind, "$HOME/.config/hypr/UserScripts/LaunchWorkKitty.sh " .. kind)
end

local function personal_browser()
  stage = "personal"
  startup.launch("vivaldi-personal", "/usr/bin/vivaldi-stable --profile-directory='Profile 1' --new-window")
  hl.timer(function()
    if stage ~= "personal" then return end
    startup.note("TIMEOUT waiting for personal Vivaldi window")
    stage = nil
    kitty("personal")
  end, { timeout = 20000, type = "oneshot" })
end

local function on_window_open(window)
  startup.run("work window placement", function()
    local class = (window.class or ""):lower()
    if class == "kitty-work" then
      place(window, workspaces.work)
    elseif class == "kitty-personal" then
      place(window, workspaces.personal)
    elseif class == "slack" or class == "com.slack.slack" then
      place(window, workspaces.slack)
    elseif class == "vivaldi-stable" or class == "vivaldi" then
      if stage == "work" then
        place(window, workspaces.work_browser)
        startup.note("MAPPED work Vivaldi to workspace " .. workspaces.work_browser)
        kitty("work")
        personal_browser()
      elseif stage == "personal" then
        place(window, workspaces.personal_browser)
        startup.note("MAPPED personal Vivaldi to workspace " .. workspaces.personal_browser)
        stage = nil
        kitty("personal")
      end
    end
  end)
end

local function start()
  if state.desktop() then
    workspaces = { work = 10, work_browser = 10, personal = 8, personal_browser = 8, slack = 9 }
  else
    workspaces = { work = 1, work_browser = 2, personal = 5, personal_browser = 4, slack = 10 }
  end

  startup.note("WORK PROFILE " .. (state.desktop() and "desktop" or "laptop"))
  hl.on("window.open", on_window_open)
  startup.launch("slack", "slack")

  if #hl.get_windows({ class = "vivaldi-stable" }) > 0 then
    startup.note("SKIP Vivaldi launch: an existing window cannot identify its profile")
    kitty("work")
    kitty("personal")
    return
  end

  stage = "work"
  startup.launch("vivaldi-work", "/usr/bin/vivaldi-stable --profile-directory=Default")
  hl.timer(function()
    if stage ~= "work" then return end
    startup.note("TIMEOUT waiting for work Vivaldi window")
    kitty("work")
    personal_browser()
  end, { timeout = 20000, type = "oneshot" })
end

return { start = start }
