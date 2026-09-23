local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function exec_once(command, label)
  local session = os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "default"
  local key = command:gsub("[^%w_.-]", "_"):sub(1, 80)
  local marker = "/tmp/hypr-work-startup-" .. session .. "-" .. key
  local runner = [[
label=$1
command=$2
printf 'START %s: %s\n' "$label" "$command"
sh -lc "$command"
status=$?
if [ "$status" -eq 0 ]; then
  printf 'DONE %s: %s\n' "$label" "$command"
else
  printf 'FAILED (%s) %s: %s\n' "$status" "$label" "$command"
fi
exit 0
]]
  local logged_command = "systemd-cat --identifier=hypr-user-startup --priority=info -- sh -c "
    .. shell_quote(runner) .. " sh " .. shell_quote(label or "work command") .. " " .. shell_quote(command)
  local script = "[ -e " .. shell_quote(marker) .. " ] || { touch " .. shell_quote(marker)
    .. " && " .. logged_command .. " & }"

  os.execute("sh -lc " .. shell_quote(script))
end

return {
  exec_once = exec_once,
}
