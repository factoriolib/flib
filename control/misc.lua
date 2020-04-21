--- @module control.misc
--- loose collection of functions that didn't fit into other modules
-- @usage local misc = require("__flib__.control.misc")

---@class Position https://lua-api.factorio.com/latest/Concepts.html#Position

local misc = {}

local math_sqrt = math.sqrt
local math_floor = math.floor
local string_format = string.format

--- calculates the distance in tiles between two positions
-- @param a Position
-- @param b Position
-- @return double
function misc.get_distance(a, b)
  local x, y = a.x-b.x, a.y-b.y
  return math_sqrt(x*x+y*y) -- sqrt shouldn't be necessary for comparing distances
end

--- converts given tick or game.tick into "[hh:]mm:ss" format
-- @param tick uint | nil
-- @return string
local format_string_1 = "%d:%02d"
local format_string_2 = "%d:%02d:%02d"
function misc.ticks_to_timestring(tick)
  local total_seconds = math_floor((tick or game.tick)/60)
  local seconds = total_seconds % 60
  local minutes = math_floor(total_seconds/60)
  if minutes > 59 then
    minutes = minutes % 60
    local hours = math_floor(total_seconds/3600)
    return string_format(format_string_2, hours, minutes, seconds)
  else
    return string_format(format_string_1, minutes, seconds)
  end
end


return misc