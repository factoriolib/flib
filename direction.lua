local flib_math = require("__flib__.math")

--- Functions for working with directions.
local flib_direction = {}

--- defines.direction.north
flib_direction.north = defines.direction.north
--- defines.direction.east
flib_direction.east = defines.direction.east
--- defines.direction.west
flib_direction.west = defines.direction.west
--- defines.direction.south
flib_direction.south = defines.direction.south
--- defines.direction.northeast
flib_direction.northeast = defines.direction.northeast
--- defines.direction.northwest
flib_direction.northwest = defines.direction.northwest
--- defines.direction.southeast
flib_direction.southeast = defines.direction.southeast
--- defines.direction.southwest
flib_direction.southwest = defines.direction.southwest

--- Returns the opposite direction.
--- @param direction defines.direction
--- @return defines.direction
function flib_direction.opposite(direction)
  return (direction + 4) % 8
end

--- Returns the next four-way or eight-way direction.
--- @param direction defines.direction
--- @param eight_way? boolean
--- @return defines.direction
function flib_direction.next(direction, eight_way)
  return (direction + (eight_way and 1 or 2)) % 8
end

--- Returns the previous four-way or eight-way direction.
--- @param direction defines.direction
--- @param eight_way? boolean
--- @return defines.direction
function flib_direction.previous(direction, eight_way)
  return (direction + (eight_way and -1 or -2)) % 8
end

--- Returns an orientation from a direction.
--- @param direction defines.direction
--- @return RealOrientation
function flib_direction.to_orientation(direction)
  return direction / 8
end

--- Returns a vector from a direction.
--- @param direction defines.direction
--- @param distance? number default: `1`
--- @return Position
function flib_direction.to_vector(direction, distance)
  distance = distance or 1
  local x, y = 0, 0
  if direction == flib_direction.north then
    y = y - distance
  elseif direction == flib_direction.northeast then
    x, y = x + distance, y - distance
  elseif direction == flib_direction.east then
    x = x + distance
  elseif direction == flib_direction.southeast then
    x, y = x + distance, y + distance
  elseif direction == flib_direction.south then
    y = y + distance
  elseif direction == flib_direction.southwest then
    x, y = x - distance, y + distance
  elseif direction == flib_direction.west then
    x = x - distance
  elseif direction == flib_direction.northwest then
    x, y = x - distance, y - distance
  end
  return { x = x, y = y }
end

--- Returns a two-dimensional vector from a cardinal direction.
--- @param direction defines.direction
--- @param longitudinal number Distance to move in the specified direction.
--- @param orthogonal number Distance to move perpendicular to the specified direction. A negative distance will move "left" and a positive distance will move "right" from the perspective of the direction.
--- @return Position
function flib_direction.to_vector_2d(direction, longitudinal, orthogonal)
  if direction == defines.direction.north then
    return { x = orthogonal, y = -longitudinal }
  elseif direction == defines.direction.south then
    return { x = -orthogonal, y = longitudinal }
  elseif direction == defines.direction.east then
    return { x = longitudinal, y = orthogonal }
  elseif direction == defines.direction.west then
    return { x = -longitudinal, y = -orthogonal }
  end
end

--- Returns the direction of travel from the source to the target.
--- @param source Position
--- @param target Position
--- @param round? boolean If true, round to the nearest `defines.direction`.
--- @return defines.direction
function flib_direction.from_positions(source, target, round)
  local deg = math.deg(math.atan2(target.y - source.y, target.x - source.x))
  local direction = (deg + 90) / 45
  if direction < 0 then
    direction = direction + 8
  end
  if round then
    direction = flib_math.round(direction)
  end
  return direction
end

return flib_direction
