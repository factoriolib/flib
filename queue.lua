--- Lua queue implementation.
--
-- Based on "Queues and Double Queues" from `Programming in Lua`: http://www.lua.org/pil/11.4.html
-- @module queue
-- @alias flib_queue
-- @usage local queue = require("__flib__.queue")
local flib_queue = {}

--- Create a new queue.
-- @treturn table
function flib_queue.new()
  return { first = 0, last = -1 }
end

--- Set a queue's metatable to allow directly calling the module's methods.
-- This will need to be re-called if the game is saved and loaded.
-- @tparam table tbl
-- @usage
-- local MyQueue = queue.load(queue.new())
-- MyQueue:push_right("My string")
-- local len = MyQueue:length() -- 1
function flib_queue.load(tbl)
  return setmetatable(tbl, { __index = flib_queue })
end

--- Push an element onto the beginning of the queue.
-- @tparam table tbl
-- @tparam any value
function flib_queue.push_left(tbl, value)
  local first = tbl.first - 1
  tbl.first = first
  tbl[first] = value
end

--- Push an element onto the end of the queue.
-- @tparam table tbl
-- @tparam any value
function flib_queue.push_right(tbl, value)
  local last = tbl.last + 1
  tbl.last = last
  tbl[last] = value
end

--- Retrieve an element from the beginning of the queue.
-- @tparam table tbl
-- @treturn any
function flib_queue.pop_left(tbl)
  local first = tbl.first
  if first > tbl.last then
    error("list is empty")
  end
  local value = tbl[first]
  tbl[first] = nil -- to allow garbage collection
  tbl.first = first + 1
  return value
end

--- Retrieve an element from the end of the queue.
-- @tparam table tbl
-- @treturn any
function flib_queue.pop_right(tbl)
  local last = tbl.last
  if tbl.first > last then
    error("list is empty")
  end
  local value = tbl[last]
  tbl[last] = nil -- to allow garbage collection
  tbl.last = last - 1
  return value
end

--- Iterate over a queue's elements from the beginning to the end.
-- @tparam table tbl
-- @treturn function
-- @usage
-- local my_queue = queue.new()
-- for i = 1, 10 do
--   queue.push_right(my_queue, 1)
-- end
--
-- -- Will print 1 through 10 in order
-- for num in queue.iter_left(my_queue) do
--   log(i)
-- end
function flib_queue.iter_left(tbl)
  local i = tbl.first - 1
  return function()
    if i < tbl.last then
      i = i + 1
      return i, tbl[i]
    end
  end
end

--- Iterate over a queue's elements from the end to the beginning.
-- @tparam table tbl
-- @treturn function
-- @usage
-- local my_queue = queue.new()
-- for i = 1, 10 do
--   queue.push_right(my_queue, 1)
-- end
--
-- -- Will print 10 through 1 in reverse order
-- for num in queue.iter_right(my_queue) do
--   log(i)
-- end
function flib_queue.iter_right(tbl)
  local i = tbl.last + 1
  return function()
    if i > tbl.first then
      i = i - 1
      return i, tbl[i]
    end
  end
end

--- Get the length of the queue.
-- @tparam table tbl
-- @treturn number
function flib_queue.length(tbl)
  return math.abs(tbl.last - tbl.first + 1)
end

return flib_queue
