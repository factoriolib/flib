--- Lua queue implementation.
---
--- Based on "Queues and Double Queues" from [Programming in Lua](http://www.lua.org/pil/11.4.html).
local flib_queue = {}

--- Create a new queue.
--- @return Queue
function flib_queue.new()
  --- @class Queue
  return { first = 0, last = -1 }
end

--- Push an element onto the beginning of the queue.
--- @param self Queue
--- @param value Queue
function flib_queue.push_left(self, value)
  local first = self.first - 1
  self.first = first
  self[first] = value
end

--- Push an element onto the end of the queue.
--- @param self Queue
--- @param value Queue
function flib_queue.push_right(self, value)
  local last = self.last + 1
  self.last = last
  self[last] = value
end

--- Retrieve an element from the beginning of the queue.
--- @param self Queue
--- @return any?
function flib_queue.pop_left(self)
  local first = self.first
  if first > self.last then
    error("list is empty")
  end
  local value = self[first]
  self[first] = nil -- to allow garbage collection
  self.first = first + 1
  return value
end

--- Retrieve an element from the end of the queue.
--- @param self Queue
--- @return any?
function flib_queue.pop_right(self)
  local last = self.last
  if self.first > last then
    error("list is empty")
  end
  local value = self[last]
  self[last] = nil -- to allow garbage collection
  self.last = last - 1
  return value
end

--- Iterate over a queue's elements from the beginning to the end.
---
--- # Examples
---
--- ```lua
--- local my_queue = queue.new()
--- for i = 1, 10 do
---   queue.push_right(my_queue, 1)
--- end
---
--- -- Will print 1 through 10 in order
--- for num in queue.iter_left(my_queue) do
---   log(i)
--- end
--- ```
--- @param self Queue
--- @return function
function flib_queue.iter_left(self)
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
--- # Examples
---
--- ```lua
--- local my_queue = queue.new()
--- for i = 1, 10 do
---   queue.push_right(my_queue, 1)
--- end
---
--- -- Will print 10 through 1 in reverse order
--- for num in queue.iter_right(my_queue) do
---   log(i)
--- end
--- ```
--- @param self Queue
--- @return function
function flib_queue.iter_right(self)
  local i = self.last + 1
  return function()
    if i > self.first then
      i = i - 1
      return i, self[i]
    end
  end
end

--- Get the length of the queue.
--- @param self Queue
--- @return number
function flib_queue.length(self)
  return math.abs(self.last - self.first + 1)
end

return flib_queue
