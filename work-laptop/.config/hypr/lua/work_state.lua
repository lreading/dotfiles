local external = "desc:ASUSTek COMPUTER INC ASUS XG49V 0x00020793"

local function dp_connected()
  for card = 0, 3 do
    for port = 1, 8 do
      local status = io.open("/sys/class/drm/card" .. card .. "-DP-" .. port .. "/status", "r")
      if status then
        local connected = status:read("*l") == "connected"
        status:close()
        if connected then return true end
      end
    end
  end
  return false
end

local function external_power()
  local supplies = io.popen("printf '%s\\n' /sys/class/power_supply/*")
  if not supplies then return false end
  local online = false
  for path in supplies:lines() do
    local type_file = io.open(path .. "/type", "r")
    local kind = type_file and type_file:read("*l")
    if type_file then type_file:close() end
    if kind == "Mains" or kind == "USB" or kind == "USB_C" or kind == "USB_PD" then
      local status = io.open(path .. "/online", "r")
      if status then
        online = status:read("*l") == "1"
        status:close()
      end
      if online then break end
    end
  end
  supplies:close()
  return online
end

return {
  external = external,
  desktop = dp_connected,
  external_power = external_power,
}
