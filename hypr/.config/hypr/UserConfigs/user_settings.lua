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

-- Replace the former 0.8 special-workspace scale with per-monitor outer gaps.
-- https://wiki.hypr.land/configuring/core/rules/workspace-rules/
-- Gaps use logical pixels; monitor.mode already accounts for scale/rotation.
local special_gap_rules = {}
local function update_special_gaps()
  local active = {}
  for _, monitor in ipairs(hl.get_monitors()) do
    if monitor.enabled and not monitor.is_mirror then
      local reserved = monitor.reserved
      local width = monitor.mode.width - reserved.left - reserved.right
      local height = monitor.mode.height - reserved.top - reserved.bottom
      local horizontal = math.max(0, math.floor(width * 0.1 + 0.5))
      local vertical = math.max(0, math.floor(height * 0.1 + 0.5))
      local selector = "s[true] m[" .. monitor.name .. "]"
      local key = selector .. ":" .. horizontal .. ":" .. vertical
      active[key] = true
      if not special_gap_rules[key] then
        special_gap_rules[key] = hl.workspace_rule({
          workspace = selector,
          gaps_out = {
            top = vertical, bottom = vertical,
            left = horizontal, right = horizontal,
          },
        })
      end
    end
  end
  -- Reuse rules when docking or changing modes instead of adding duplicates.
  for key, rule in pairs(special_gap_rules) do
    local enabled = active[key] == true
    if rule:is_enabled() ~= enabled then rule:set_enabled(enabled) end
  end
end

hl.on("config.reloaded", update_special_gaps)
hl.on("hyprland.start", update_special_gaps)
hl.on("monitor.layout_changed", update_special_gaps)

-- Disable the three-finger gestures registered by the base configuration.
for _, direction in ipairs({ "horizontal", "up", "down" }) do
  hl.gesture({ fingers = 3, direction = direction, action = "unset" })
end
