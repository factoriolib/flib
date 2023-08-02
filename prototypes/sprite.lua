-- INDICATOR SPRITES

local indicators = {}
for i, color in ipairs({ "black", "white", "red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink" }) do
  indicators[i] = {
    type = "sprite",
    name = "flib_indicator_" .. color,
    filename = "__flib__/graphics/indicators.png",
    y = (i - 1) * 32,
    size = 32,
    flags = { "icon" },
  }
end
data:extend(indicators)

local fab = "__flib__/graphics/frame-action-icons.png"

data:extend({
  { type = "sprite", name = "flib_pin_black", filename = fab, position = { 0, 0 }, size = 32, flags = { "gui-icon" } },
  { type = "sprite", name = "flib_pin_white", filename = fab, position = { 32, 0 }, size = 32, flags = { "gui-icon" } },
  {
    type = "sprite",
    name = "flib_pin_disabled",
    filename = fab,
    position = { 64, 0 },
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "flib_settings_black",
    filename = fab,
    position = { 0, 32 },
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "flib_settings_white",
    filename = fab,
    position = { 32, 32 },
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "flib_settings_disabled",
    filename = fab,
    position = { 64, 32 },
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "flib_nav_backward_black",
    filename = "__flib__/graphics/nav-backward-black.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "flib_nav_backward_white",
    filename = "__flib__/graphics/nav-backward-white.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "flib_nav_backward_disabled",
    filename = "__flib__/graphics/nav-backward-disabled.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "flib_nav_forward_black",
    filename = "__flib__/graphics/nav-forward-black.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "flib_nav_forward_white",
    filename = "__flib__/graphics/nav-forward-white.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "flib_nav_forward_disabled",
    filename = "__flib__/graphics/nav-forward-disabled.png",
    size = 32,
    flags = { "gui-icon" },
  },
})
