local Test = require('tests.factorio_luaunit')
local math = require('__flib__.math')
math.randomseed(os.clock())

--- @diagnostic disable: undefined-field

function Test_radians()
  for i = 1, 90 do Test.assertAlmostEquals(i * math.radians, math.rad(i), .1) end
end

function Test_degrees()
  for i = 1, 90 do Test.assertAlmostEquals(i * math.degrees, math.deg(i), .1) end
end

function Test_round()
  Test.assertEquals(math.round(3.51), 4)
  Test.assertEquals(math.round(3.51, .1), 3.5)
end

function Test_ceiled()
  Test.assertEquals(math.ceiled(3.7), 4)
  Test.assertEquals(math.ceiled(3.7), math.ceil(3.7))
  Test.assertEquals(math.ceiled(-3.7), -3)
  Test.assertEquals(math.ceiled(-3.7), math.ceil(-3.7))
  Test.assertAlmostEquals(math.ceiled(-3.75, .1), -3.8, .1)
end

function Test_floored()
  Test.assertEquals(math.floored(3.7), 3)
  Test.assertEquals(math.floored(3.7), math.floor(3.7))
  Test.assertEquals(math.floored(-3.7), -4)
  Test.assertEquals(math.floored(-3.7), math.floor(-3.7))
  Test.assertAlmostEquals(math.floored(-3.75, .1), -3.8, .1)
end

function Test_clamp()
  Test.assertEquals(math.clamp(0, 1, 2), 1)
  Test.assertEquals(math.clamp(0, 0, 2), 0)
  Test.assertEquals(math.clamp(0, 0, 0), 0)

  Test.assertEquals(math.clamp(0, -10, 10), 0)
  Test.assertEquals(math.clamp(-100, -10, 10), -10)
  Test.assertEquals(math.clamp(100, -10, 10), 10)

  Test.assertEquals(math.clamp(-2), 0)
  Test.assertEquals(math.clamp(.5), .5)
  Test.assertEquals(math.clamp(3), 1)

  --- Max is smaller than min
  Test.assertEquals(math.clamp(0, 1, 0), 1)
  Test.assertEquals(math.clamp(2, 1, 0), 0)
  Test.assertEquals(math.clamp(1, 1, 0), 0)

end

local values1 = { 25, 25, 25, 25 }
local values2 = { 10, 25, 40, 45, 50 }
local values3 = { 10, 25, 40, -50, -45  }
local values4 = {-23, -12, -50, -10, -33}

function Test_maximum()
  Test.assertEquals(math.maximum(values1), 25)
  Test.assertEquals(math.maximum(values2), 50)
  Test.assertEquals(math.maximum(values3), 40)
  Test.assertEquals(math.maximum(values4), -10)
  for _ = 1, 5 do
    local rando = {}
    while #rando < 11 do rando[#rando + 1] = math.random(-50, 50) end
    Test.assertEquals(math.maximum(rando), math.max(table.unpack(rando)))
  end
end

function Test_minimum()
  Test.assertEquals(math.minimum(values1), 25)
  Test.assertEquals(math.minimum(values2), 10)
  Test.assertEquals(math.minimum(values3), -50)
  Test.assertEquals(math.minimum(values4), -50)
  for _ = 1, 5 do
    local rando = {}
    while #rando < 11 do rando[#rando + 1] = math.random(-50, 50) end
    Test.assertEquals(math.minimum(rando), math.min(table.unpack(rando)))
  end
end

function Test_sum()
  Test.assertEquals(math.sum(values1), 100)
  Test.assertEquals(math.sum(values2), 185)
  Test.assertEquals(math.sum(values3), -5)
  Test.assertEquals(math.sum(values4), -117)
end

function Test_mean()
  Test.assertEquals(math.mean(values1), 25)
  Test.assertEquals(math.mean(values2), 37)
  Test.assertEquals(math.mean(values3), -1)
  Test.assertEquals(math.mean(values4), -23.4)
end

function Test_midrange()
  Test.assertEquals(math.midrange(values1), 25)
  Test.assertEquals(math.midrange(values2), 30)
  Test.assertEquals(math.midrange(values3), -5)
  Test.assertEquals(math.midrange(values4), -30)
end

function Test_range()
  Test.assertEquals(math.range(values1), 0)
  Test.assertEquals(math.range(values2), 40)
  Test.assertEquals(math.range(values3), 90)
  Test.assertEquals(math.range(values4), 40)
end

function Test_sign()
  Test.assertEquals(math.sign(0), 1)
  Test.assertEquals(math.sign(1), 1)
  Test.assertEquals(math.sign(-1), -1)
end

function Test_lerp()
  Test.assertEquals(math.lerp(1, 2, .5), 1.5)
  Test.assertEquals(math.lerp(0, 10, .25), 2.5)
end

Test.Run()
