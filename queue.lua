if ... ~= "__flib__.queue" then
  return require("__flib__.queue")
end

--- Lua queue implementation.
---
--- Based on "Queues and Double Queues" from [Programming in Lua](http://www.lua.org/pil/11.4.html).
--- ```lua
--- local flib_queue = require("__flib__.queue")
--- ```
--- @class flib_queue
local flib_queue = {}

---@class flib.Queue<T>: { [integer]: T, first: integer, last: integer }

--- Create a new queue.
--- @return flib.Queue
function flib_queue.new()
  return { first = 0, last = -1 }
end

--- Push an element into the front of the queue.
--- @generic T
--- @param self flib.Queue<T>
--- @param value T
function flib_queue.push_front(self, value)
  local first = self.first - 1
  self.first = first
  self[first] = value
end

--- Push an element into the back of the queue.
--- @generic T
--- @param self flib.Queue<T>
--- @param value `T`
function flib_queue.push_back(self, value)
  local last = self.last + 1
  self.last = last
  self[last] = value
end

--- Retrieve an element from the front of the queue.
--- @generic T
--- @param self flib.Queue<T>
--- @return T?
function flib_queue.pop_front(self)
  local first = self.first
  if first > self.last then
    return
  end
  local value = self[first]
  self[first] = nil
  self.first = first + 1
  return value
end

--- Retrieve an element from the back of the queue.
--- @generic T
--- @param self flib.Queue<T>
--- @return T?
function flib_queue.pop_back(self)
  local last = self.last
  if self.first > last then
    return
  end
  local value = self[last]
  self[last] = nil
  self.last = last - 1
  return value
end

--- Iterate over a queue's elements from the beginning to the end.
---
--- # Example
---
--- ```lua
--- local my_queue = queue.new()
--- for i = 1, 10 do
---   queue.push_back(my_queue, 1)
--- end
---
--- -- 1 2 3 4 5 6 7 8 9 10
--- for num in queue.iter(my_queue) do
---   log(i)
--- end
--- ```
--- @generic T
--- @param self flib.Queue<T>
--- @return fun(self: flib.Queue<T>, index: integer): T
function flib_queue.iter(self)
  local i = self.first - 1
  return function()
    if i < self.last then
      i = i + 1
      return i, self[i]
    end
  end
end

--- Iterate over a queue's elements from the end to the beginning.
---
--- # Example
---
--- ```lua
--- local my_queue = queue.new()
--- for i = 1, 10 do
---   queue.push_back(my_queue, 1)
--- end
---
--- -- 10 9 8 7 6 5 4 3 2 1
--- for num in queue.iter_rev(my_queue) do
---   log(i)
--- end
--- ```
--- @generic T
--- @param self flib.Queue<T>
--- @return fun(self: flib.Queue<T>, index: integer): T
function flib_queue.iter_rev(self)
  local i = self.last + 1
  return function()
    if i > self.first then
      i = i - 1
      return i, self[i]
    end
  end
end

--- Get the length of the queue.
--- @generic T
--- @param self flib.Queue<T>
--- @return number
function flib_queue.length(self)
  return math.abs(self.last - self.first + 1)
end

return flib_queue
