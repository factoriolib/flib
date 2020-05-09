--- Miscellaneous control-stage functions that don't yet have a proper home.
-- @module control.misc
-- @usage local misc = require("__flib__.control.misc")
local misc = {}

local math_sqrt = math.sqrt
local math_floor = math.floor
local string_format = string.format

--- Calculate the distance in tiles between two positions.
-- @tparam Concepts.Position pos1
-- @tparam Concepts.Position pos2
-- @return double
function misc.get_distance(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local y1 = pos1.y or pos1[2]
  local x2 = pos2.x or pos2[1]
  local y2 = pos2.y or pos2[2]
  return math_sqrt((x1-x2)^2 + (y1-y2)^2)
end

--- Calculate the squared distance in tiles between two positions.
-- @tparam Concepts.Position pos1
-- @tparam Concepts.Position pos2
-- @return double
function misc.get_distance_squared(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local y1 = pos1.y or pos1[2]
  local x2 = pos2.x or pos2[1]
  local y2 = pos2.y or pos2[2]
  return (x1-x2)^2 + (y1-y2)^2
end

local format_string_1 = "%d:%02d"
local format_string_2 = "%d:%02d:%02d"

--- Convert given tick or game.tick into "[hh:]mm:ss" format.
-- @tparam[opt=game.tick] uint tick
-- @return string
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
