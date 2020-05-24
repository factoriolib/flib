--- Extends Lua 5.2 math.
-- @module math
-- @see math
-- @usage local math = require('__flib__/math')

local M = {}

for k, v in pairs(math) do
  M[k] = v
end

local math_abs = math.abs
local math_floor = math.floor
local math_ceil = math.ceil
local math_min = math.min
local math_max = math.max
local math_huge = math.huge
local math_pi = math.pi
local math_log = math.log
local unpack = table.unpack

--(( Math Constants
M.DEG2RAD = math_pi / 180
M.RAD2DEG = 180 / math_pi
M.EPSILON = 1.401298e-45

M.MAXINT8 = 128
M.MININT8 = -128
M.MAXUINT8 = 255

M.MAX_INT8 = M.MAXINT8
M.MIN_INT8 = M.MININT8
M.MAX_UINT8 = M.MAXUINT8

M.MAXINT16 = 32768
M.MININT16 = -32768
M.MAXUINT16 = 65535
M.MAX_INT16 = M.MAXINT16
M.MIN_INT16 = M.MININT16
M.MAX_UINT16 = M.MAXUINT16

M.MAXINT = 2147483648
M.MAX_INT = M.MAXINT
M.MAXINT32 = M.MAXINT
M.MAX_INT32 = M.MAXINT

M.MAXUINT = 4294967296
M.MAX_UINT = M.MAXUINT
M.MAXUINT32 = M.MAXUINT
M.MAX_UINT32 = M.MAXUINT

M.MININT = -2147483648
M.MIN_INT = M.MININT
M.MININT32 = M.MININT
M.MIN_INT32 = M.MININT

M.MAXINT64 = 9223372036854775808
M.MININT64 = -9223372036854775808
M.MAXUINT64 = 18446744073709551615
M.MAX_INT64 = M.MAXINT64
M.MIN_INT64 = M.MININT64
M.MAX_UINT64 = M.MAXUINT64
--))

local function tuple(...)
  return type(...) == 'table' and ... or {...}
end

function M.log10(x)
  return math_log(x, 10)
end

--- Round a number.
-- @tparam number x
-- @treturn number the rounded number
function M.round(x)
  return x >= 0 and math_floor(x + 0.5) or math_ceil(x - 0.5)
end

-- Returns the number x rounded to p decimal places.
-- @tparam number x
-- @tparam[opt=0] int p the number of decimal places to round to
-- @treturn number rounded to p decimal spaces.
function M.round_to(x, p)
  local e = 10 ^ (p or 0)
  return math_floor(x * e + 0.5) / e
end

-- Returns the number floored to p decimal spaces.
-- @tparam number x
-- @tparam[opt=0] int p the number of decimal places to floor to
-- @treturn number floored to p decimal spaces.
function M.floor_to(x, p)
  if (p or 0) == 0 then
    return math_floor(x)
  end
  local e = 10 ^ p
  return math_floor(x * e) / e
end

-- Returns the number ceiled to p decimal spaces.
-- @tparam number x
-- @tparam[opt=0] int p the number of decimal places to ceil to
-- @treturn number ceiled to p decimal spaces.
function M.ceil_to(x, p)
  local e = 10 ^ (p or 0)
  return math_ceil(x * e + 0.5) / e
end

-- Various average (means) algorithms implementation
-- See: http://en.wikipedia.org/wiki/Average

--- Calculates the sum of a sequence of values.
-- @tparam tuple ... a tuple of numbers
-- @treturn the sum
function M.sum(...)
  local x = tuple(...)
  local s = 0
  for _, v in ipairs(x) do
    s = s + v
  end
  return s
end

--- Calculates the arithmetic mean of a set of values.
-- @tparam array x an array of numbers
-- @treturn number the arithmetic mean
function M.arithmetic_mean(...)
  local x = tuple(...)
  return (M.sum(x) / #x)
end

M.avg = M.arithmetic_mean
M.average = M.arithmetic_mean

--- Calculates the geometric mean of a set of values.
-- @tparam array x an array of numbers
-- @treturn number the geometric mean
function M.geometric_mean(...)
  local x = tuple(...)
  local prod = 1
  for _, v in ipairs(x) do
    prod = prod * v
  end
  return (prod ^ (1 / #x))
end

--- Calculates the harmonic mean of a set of values.
-- @tparam tuple ... an array of numbers
-- @treturn number the harmonic mean
function M.harmonic_mean(...)
  local x = tuple(...)
  local s = 0
  for _, v in ipairs(x) do
    s = s + (1 / v)
  end
  return (#x / s)
end

--- Calculates the quadratic mean of a set of values.
-- @tparam tuple ... an array of numbers
-- @treturn number the quadratic mean
function M.quadratic_mean(...)
  local x = tuple(...)
  local squares = 0
  for _, v in ipairs(x) do
    squares = squares + (v * v)
  end
  return math.sqrt((1 / #x) * squares)
end

--- Calculates the generalized mean (to a specified power) of a set of values.
-- @tparam number p power
-- @tparam tuple ... an array of numbers
-- @treturn number the generalized mean
function M.generalized_mean(p, ...)
  local x = tuple(...)
  local sump = 0
  for _, v in ipairs(x) do
    sump = sump + (v ^ p)
  end
  return ((1 / #x) * sump) ^ (1 / p)
end

--- Calculates the weighted mean of a set of values.
-- @tparam array x an array of numbers
-- @tparam array w an array of number weights for each value
-- @treturn number the weighted mean
function M.weighted_mean(x, w)
  local sump = 0
  for i, v in ipairs(x) do
    sump = sump + (v * w[i])
  end
  return sump / M.sum(w)
end

--- Calculates the midrange mean of a set of values.
-- @tparam array x an array of numbers
-- @treturn number the midrange mean
function M.midrange_mean(...)
  local x = tuple(...)
  return 0.5 * (math_min(unpack(x)) + math_max(unpack(x)))
end

--- Calculates the energetic mean of a set of values.
-- @tparam array x an array of numbers
-- @treturn number the energetic mean
function M.energetic_mean(...)
  local x = tuple(...)
  local s = 0
  for _, v in ipairs(x) do
    s = s + (10 ^ (v / 10))
  end
  return 10 * M.log10((1 / #x) * s)
end

--- Returns the number x clamped between the numbers min and max.
-- @tparam number x
-- @tparam number min
-- @tparam number max
-- @treturn number clamped between min and max
function M.clamp(x, min, max)
  min, max = min or 0, max or 1
  return x < min and min or (x > max and max or x)
end

--- Linear interpolation or 2 numbers.
-- @tparam number a
-- @tparam number b
-- @tparam float amount
-- @treturn number
function M.lerp(a, b, amount)
  return a + (b - a) * M.clamp(amount, 0, 1)
end

--- Smooth.
-- @tparam number a
-- @tparam number b
-- @tparam float amount
-- @treturn number
function M.smooth(a, b, amount)
  local t = M.clamp(amount, 0, 1)
  local m = t * t * (3 - 2 * t)
  return a + (b - a) * m
end

--- Approximately the same
-- @tparam number a
-- @tparam number b
-- @treturn boolean
function M.approximately(a, b)
  return math_abs(b - a) < math_max(1e-6 * math_max(math_abs(a), math_abs(b)), 1.121039e-44)
end

--- Is x a number.
-- @tparam number x
-- @treturn boolean
function M.is_number(x)
  return x == x and x ~= math_huge
end

--- Is x an integer.
-- @tparam number x
-- @treturn boolean
function M.is_integer(x)
  return x == math_ceil(x)
end

--- Is x unsigned.
-- @tparam number x
-- @treturn boolean
function M.is_unsigned(x)
  return x >= 0
end

return M
