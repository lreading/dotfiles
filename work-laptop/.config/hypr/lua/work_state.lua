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

return {
  external = external,
  desktop = dp_connected,
}
