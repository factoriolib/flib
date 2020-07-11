--- Functions for working with orientations.
-- @module orientation
-- @alias flib_orientation
-- @usage local orientation = require('__flib__.orientation')

local flib_orientation = {}

--- north orientation
flib_orientation.north = defines.direction.north / 8
--- east orientation
flib_orientation.east = defines.direction.east / 8
--- west orientation
flib_orientation.west = defines.direction.west / 8
--- south orientation
flib_orientation.south = defines.direction.south / 8
--- northeast orientation
flib_orientation.northeast = defines.direction.northeast / 8
--- northwest orientation
flib_orientation.northwest = defines.direction.northwest / 8
--- southeast orientation
flib_orientation.southeast = defines.direction.southeast / 8
--- southwest orientation
flib_orientation.southwest = defines.direction.southwest / 8

local floor = math.floor
local atan2 = math.atan2
local pi = math.pi
local abs = math.abs

--- Returns a 4way or 8way direction from an orientation.
-- @tparam float orientation
-- @tparam[opt=false] boolean eight_way
-- @treturn defines.direction
function flib_orientation.to_direction(orientation, eight_way)
  local ways = eight_way and 8 or 4
  local mod = eight_way and 1 or 2
  return floor(orientation * ways + 0.5) % ways * mod
end

--- Returns the opposite orientation.
-- @tparam float orientation
-- @treturn float the opposite orientation
function flib_orientation.opposite(orientation)
  return (orientation + 0.5) % 1
end

--- Add two orientations together.
-- @tparam float orientation1
-- @tparam float orientation2
-- @treturn float the orientations added together
function flib_orientation.add(orientation1, orientation2)
  return (orientation1 + orientation2) % 1
end

function flib_orientation.get_orientation(entitypos, targetpos)
  local x = targetpos.x or targetpos[1] - entitypos.x or entitypos[1]
  local y = targetpos.y or targetpos[2] - entitypos.y or entitypos[2]
  return (atan2(y, x) / 2 / pi + 0.25) % 1
end

function flib_orientation.orientation_match(orientation1, orientation2)
  return abs(orientation1 - orientation2) < 0.25 or abs(orientation1 - orientation2) > 0.75
end

return flib_orientation