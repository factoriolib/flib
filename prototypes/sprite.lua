-- INDICATOR SPRITES

local indicators = {}
for i, color in ipairs{"black", "white", "red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink"} do
  indicators[i] = {
    type = "sprite",
    name = "flib_indicator_"..color,
    filename = "__flib__/graphics/indicators.png",
    y = (i - 1) * 32,
    size = 32,
    flags = {"icon"}
  }
end
data:extend(indicators)