local position = require("__flib__.position")

local res = position.add({ 1, 3 }, { -2, 1 })
assert(res[1] == -1)
assert(res[2] == 4)

local res = position.ceil({ 1.2, 1.1 })
assert(res[1] == 2)
assert(res[2] == 2)

local res = position.from_chunk({ 1, 3 })
assert(res[1] == 32)
assert(res[2] == 96)

assert(position.distance({ 1, 3 }, { 2, 4 }) == math.sqrt(2))
assert(position.distance_squared({ 1, 3 }, { 2, 4 }) == 2)

local res = position.div({ 1, 2 }, { 5, 3 })
assert(res[1] == 0.2)
assert(res[2] == (2 / 3))
local res = position.div({ x = 1, y = 2 }, { x = 5, y = 3 })
assert(res.x == 0.2)
assert(res.y == (2 / 3))

local res = position.ensure_explicit({ x = 1, y = 2 })
assert(res.x == 1)
assert(res.y == 2)
local res = position.ensure_explicit({ 1, 2 })
assert(res.x == 1)
assert(res.y == 2)

local res = position.ensure_short({ x = 1, y = 2 })
assert(res[1] == 1)
assert(res[2] == 2)
local res = position.ensure_short({ 1, 2 })
assert(res[1] == 1)
assert(res[2] == 2)

assert(position.eq({ 1, 1 }, { 1, 1 }))
assert(not position.eq({ 1, 3 }, { 1, 1 }))
assert(not position.eq({ 3, 3 }, { 1, 1 }))

local res = position.floor({ 1.1, 2.2 })
assert(res[1] == 1)
assert(res[2] == 2)

local res = position.from_chunk({ 1, 2 })
assert(res[1] == 32)
assert(res[2] == 64)

assert(position.le({ 1, 1 }, { 1, 1 }))
assert(position.le({ 1, 0 }, { 1, 1 }))
assert(position.le({ 0, 0 }, { 1, 1 }))
assert(not position.le({ 2, 1 }, { 1, 1 }))
assert(not position.le({ 2, 2 }, { 1, 1 }))

assert(position.lt({ 0, 0 }, { 1, 1 }))
assert(not position.lt({ 1, 1 }, { 1, 1 }))
assert(not position.lt({ 1, 0 }, { 1, 1 }))
assert(not position.lt({ 2, 1 }, { 1, 1 }))
assert(not position.lt({ 2, 2 }, { 1, 1 }))

local res = position.mod({ 4.5, 3 }, { 3, 3 })
assert(res[1] == 1.5)
assert(res[2] == 0)

local res = position.mul({ 4.5, 3 }, { 3, 3 })
assert(res[1] == 13.5)
assert(res[2] == 9)

local res = position.sub({ 4.5, 3 }, { 3, 3 })
assert(res[1] == 1.5)
assert(res[2] == 0)

local res = position.pow({ 3, 3 }, { 3, 2 })
assert(res[1] == 27)
assert(res[2] == 9)

local res = position.to_chunk({ 100, 150 })
assert(res[1] == 3)
assert(res[2] == 4)

local res = position.to_tile({ 3.2, 3.5 })
assert(res[1] == 3)
assert(res[2] == 3)
