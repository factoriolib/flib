--- Utilities for manipulating positions. All functions support both the shorthand and explicit syntaxes and will
--- preserve the syntax that was passed in.
local flib_position = {}

--- Aggregate type of the various Factorio position types.
--- @alias Position ChunkPosition|MapPosition|TilePosition

--- Add two positions.
--- @param pos1 Position
--- @param pos2 Position
--- @return Position
function flib_position.add(pos1, pos2)
  return flib_position.operate(pos1, pos2, function(first, second)
    return first + second
  end)
end

--- Ceil the given position.
--- @param pos Position
--- @return Position
function flib_position.ceil(pos)
  if pos.x then
    return { x = math.ceil(pos.x), y = math.ceil(pos.y) }
  else
    return { math.ceil(pos[1]), math.ceil(pos[2]) }
  end
end

--- Perform an arbitrary comparison on two positions. `op` is first passed both x positions, then both y positions. If
--- any result is `false`, the whole result is `false`.
--- @param pos1 Position
--- @param pos2 Position
--- @param op fun(double, double): boolean
--- @return boolean
function flib_position.compare(pos1, pos2, op)
  local pos1_e = flib_position.ensure_xy(pos1)
  local pos2_e = flib_position.ensure_xy(pos2)
  return op(pos1_e.x, pos2_e.x) and op(pos1_e.y, pos2_e.y)
end

--- Calculate the distance between two positions.
--- @param pos1 Position
--- @param pos2 Position
--- @return number
function flib_position.distance(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local y1 = pos1.y or pos1[2]
  local x2 = pos2.x or pos2[1]
  local y2 = pos2.y or pos2[2]
  return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

--- Calculate the squared distance between two positions.
--- @param pos1 Position
--- @param pos2 Position
--- @return number
function flib_position.distance_squared(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local y1 = pos1.y or pos1[2]
  local x2 = pos2.x or pos2[1]
  local y2 = pos2.y or pos2[2]
  return (x1 - x2) ^ 2 + (y1 - y2) ^ 2
end

--- Divide two positions.
--- @param pos1 Position
--- @param pos2 Position
--- @return Position
function flib_position.div(pos1, pos2)
  return flib_position.operate(pos1, pos2, function(first, second)
    return first / second
  end)
end

--- Ensure that the passed `Position` is in shorthand form, and convert it if it is not.
--- @param pos Position
--- @return Position
function flib_position.ensure_short(pos)
  if pos.x and pos.y then
    return { pos.x, pos.y }
  else
    return pos
  end
end

--- Ensure that the passed `Position` has explicit x and y keys, and convert it if it does not.
--- @param pos Position
--- @return Position
function flib_position.ensure_xy(pos)
  if pos.x and pos.y then
    return pos
  else
    return { x = pos[1], y = pos[2] }
  end
end

--- Test if two positions are equal.
--- @param pos1 Position
--- @param pos2 Position
--- @return boolean
function flib_position.eq(pos1, pos2)
  return flib_position.compare(pos1, pos2, function(first, second)
    return first == second
  end)
end

--- Floor the given position.
--- @param pos Position
--- @return Position
function flib_position.floor(pos)
  if pos.x then
    return { x = math.floor(pos.x), y = math.floor(pos.y) }
  else
    return { math.floor(pos[1]), math.floor(pos[2]) }
  end
end

--- Convert a `ChunkPosition` into a `TilePosition`.
--- @param pos ChunkPosition
--- @return TilePosition
function flib_position.from_chunk(pos)
  if pos.x then
    return { x = pos.x * 32, y = pos.y * 32 }
  else
    return { pos[1] * 32, pos[2] * 32 }
  end
end

--- Test if `pos1` is less than or equal to `pos2`.
--- @param pos1 Position
--- @param pos2 Position
--- @return boolean
function flib_position.le(pos1, pos2)
  return flib_position.compare(pos1, pos2, function(first, second)
    return first <= second
  end)
end

--- Test if `pos1` is less than `pos2`.
--- @param pos1 Position
--- @param pos2 Position
--- @return boolean
function flib_position.lt(pos1, pos2)
  return flib_position.compare(pos1, pos2, function(first, second)
    return first < second
  end)
end

--- Perform an arbitrary operation on a position. `op` is first passed the x position, then the y position, and the
--- return values are mapped to the return position.
--- @param pos Position
--- @param op fun(double): double
--- @return Position
function flib_position.map(pos, op)
  if pos.x then
    return { x = op(pos.x), y = op(pos.y) }
  else
    return { op(pos[1]), op(pos[2]) }
  end
end

--- Take the remainder (modulus) of two positions.
--- @param pos1 Position
--- @param pos2 Position
--- @return Position
function flib_position.mod(pos1, pos2)
  return flib_position.operate(pos1, pos2, function(first, second)
    return first % second
  end)
end

--- Multiply two positions.
--- @param pos1 Position
--- @param pos2 Position
--- @return Position
function flib_position.mul(pos1, pos2)
  return flib_position.operate(pos1, pos2, function(first, second)
    return first * second
  end)
end

--- Perform an arbitrary operation on two positions. `op` is first passed both x positions, then both y positions, and
--- the return values are mapped to the return position.
--- @param pos1 Position
--- @param pos2 Position
--- @param op fun(double, double): double
--- @return Position
function flib_position.operate(pos1, pos2, op)
  local pos1_e = flib_position.ensure_xy(pos1)
  local pos2_e = flib_position.ensure_xy(pos2)
  local out_x = op(pos1_e.x, pos2_e.x)
  local out_y = op(pos1_e.y, pos2_e.y)
  if pos1.x then
    return { x = out_x, y = out_y }
  else
    return { out_x, out_y }
  end
end

--- Subtract two positions.
--- @param pos1 Position
--- @param pos2 Position
--- @return Position
function flib_position.sub(pos1, pos2)
  return flib_position.operate(pos1, pos2, function(first, second)
    return first - second
  end)
end

--- Take the power of two positions. `pos1^pos2`.
--- @param pos1 Position
--- @param pos2 Position
--- @return Position
function flib_position.pow(pos1, pos2)
  return flib_position.operate(pos1, pos2, function(first, second)
    return first ^ second
  end)
end

--- Convert a `MapPosition` or `TilePosition` into a `ChunkPosition`.
--- @param pos MapPosition|TilePosition
--- @return ChunkPosition
function flib_position.to_chunk(pos)
  if pos.x then
    return { x = math.floor(pos.x / 32), y = math.floor(pos.y / 32) }
  else
    return { math.floor(pos[1] / 32), math.floor(pos[2] / 32) }
  end
end

--- Convert a `MapPosition` into a `TilePosition`. This is effectively identical to `flib_position.floor`, but changes
--- the result type.
--- @param pos MapPosition
--- @return TilePosition
function flib_position.to_tile(pos)
  if pos.x then
    return { x = math.floor(pos.x), y = math.floor(pos.y) }
  else
    return { math.floor(pos[1]), math.floor(pos[2]) }
  end
end

return flib_position
