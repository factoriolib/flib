local flib_position = {}

local meta = {
  __index = flib_position,
  __unm = flib_position.negate,
  __add = flib_position.add,
  __sub = flib_position.subtract,
  __mul = flib_position.multiply,
  __div = flib_position.divide,
  __mod = flib_position.modulus,
  __pow = flib_position.pow,
}

--- Constructors / converters
-- @section

function flib_position.from_shorthand(pos)
  return {
    x = pos.x or pos[1],
    y = pos.y or pos[2],
  }
end

function flib_position.load(pos)
  local pos = pos
  if not pos.x or not pos.y then
    pos = flib_position.from_shorthand(pos)
  end
  return setmetatable(pos, )
end

function flib_position.to_shorthand(pos)
  return {
    pos.x or pos[1],
    pos.y or pos[2],
  }
end

--- Mathmatical operations
-- @section

--- Add two positions.
-- @tparam Position self
-- @tparam Position other_pos
-- @treturn Position
function flib_position.add(self, other_pos)
  self.x = self.x + other_pos.x
  self.y = self.y + other_pos.y
  return self
end

--- Divide two positions.
-- @tparam Position self
-- @tparam Position other_pos
-- @treturn Position
function flib_position.divide(self, other_pos)
  self.x = self.x / other_pos.x
  self.y = self.y / other_pos.y
  return self
end

--- Modulus two positions.
-- @tparam Position self
-- @tparam Position other_pos
-- @treturn Position
function flib_position.modulus(self, other_pos)
  self.x = self.x % other_pos.x
  self.y = self.y % other_pos.y
  return self
end

--- Multiply two positions.
-- @tparam Position self
-- @tparam Position other_pos
-- @treturn Position
function flib_position.multiply(self, other_pos)
  self.x = self.x * other_pos.x
  self.y = self.y * other_pos.y
  return self
end

--- Negate a position.
-- @tparam Position self
-- @treturn Position
function flib_position.negate(self)
  self.x = -self.x
  self.y = -self.y
  return self
end

--- Raise the position to the power of another.
-- @tparam Position self
-- @tparam Position other_pos
-- @treturn Position
function flib_position.pow(self, other_pos)
  self.x = self.x ^ other_pos.x
  self.y = self.y ^ other_pos.y
  return self
end

--- Subtract two positions.
-- @tparam Position self
-- @tparam Position other_pos
-- @treturn Position
function flib_position.subtract(self, other_pos)
  self.x = self.x - other_pos.x
  self.y = self.y - other_pos.y
  return self
end

return flib_position
