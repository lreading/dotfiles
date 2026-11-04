hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "pc105",
  },
  master = { new_status = "master", new_on_top = true, mfact = 0.5 },
  misc = {
    vrr = 2,
  },
  cursor = {
    no_hardware_cursors = 2,
  },
})

-- Disable the three-finger gestures registered by the base configuration.
for _, direction in ipairs({ "horizontal", "up", "down" }) do
  hl.gesture({ fingers = 3, direction = direction, action = "unset" })
end
