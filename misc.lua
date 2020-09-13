--- Miscellaneous control-stage functions that don't yet have a proper home.
-- @module misc
-- @alias flib_misc
-- @usage local misc = require("__flib__.misc")
local flib_misc = {}

local math = math
local string = string
--- Calculate the distance in tiles between two positions.
-- @tparam Concepts.Position pos1
-- @tparam Concepts.Position pos2
-- @treturn number
function flib_misc.get_distance(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local y1 = pos1.y or pos1[2]
  local x2 = pos2.x or pos2[1]
  local y2 = pos2.y or pos2[2]
  return math.sqrt((x1-x2)^2 + (y1-y2)^2)
end

--- Calculate the squared distance in tiles between two positions.
-- @tparam Concepts.Position pos1
-- @tparam Concepts.Position pos2
-- @treturn number
function flib_misc.get_distance_squared(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local y1 = pos1.y or pos1[2]
  local x2 = pos2.x or pos2[1]
  local y2 = pos2.y or pos2[2]
  return (x1-x2)^2 + (y1-y2)^2
end

local format_string_1 = "%d:%02d"
local format_string_2 = "%d:%02d:%02d"

--- Convert given tick or game.tick into "[hh:]mm:ss" format.
-- @tparam[opt=game.tick] number tick
-- @treturn string
function flib_misc.ticks_to_timestring(tick)
  local total_seconds = math.floor((tick or game.tick)/60)
  local seconds = total_seconds % 60
  local minutes = math.floor(total_seconds/60)
  if minutes > 59 then
    minutes = minutes % 60
    local hours = math.floor(total_seconds/3600)
    return string.format(format_string_2, hours, minutes, seconds)
  else
    return string.format(format_string_1, minutes, seconds)
  end
end

return flib_misc