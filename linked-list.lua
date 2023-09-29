--- @class LinkedListNode<T>: { next: LinkedListNode<T>?, prev: LinkedListNode<T>?, value: T }

--- Doubly linked list.
--- @class LinkedList<T>: { head: LinkedListNode<T>, tail: LinkedListNode<T>, len: integer }

--- @class flib_linked_list
local flib_linked_list = {}

--- @return LinkedList
function flib_linked_list.new()
  return { len = 0 }
end

--- @generic T
--- @param self LinkedList<T>
--- @param value T
function flib_linked_list.push_back(self, value)
  local node = { prev = self.tail, value = value }
  if not self.tail then
    self.head = node
    self.tail = node
    self.len = 1
    return
  end
  self.tail.next = node
  self.tail = node
  self.len = self.len + 1
end

--- @generic T
--- @param self LinkedList<T>
--- @param value T
function flib_linked_list.push_front(self, value)
  local node = { next = self.head, value = value }
  if not self.head then
    self.head = node
    self.tail = node
    self.len = 1
    return
  end
  self.head.prev = node
  self.head = node
  self.len = self.len + 1
end

--- @generic T
--- @param self LinkedList<T>
--- @return T?
function flib_linked_list.pop_back(self)
  local node = self.tail
  if not node then
    return
  end
  if node.prev then
    node.prev.next = nil
  end
  self.tail = node.prev
  if node == self.head then
    self.head = nil
  end
  self.len = self.len - 1
  return node.value
end

--- @generic T
--- @param self LinkedList<T>
--- @return T?
function flib_linked_list.pop_front(self)
  local node = self.head
  if not node then
    return
  end
  if node.next then
    node.next.prev = nil
  end
  self.head = node.next
  if node == self.tail then
    self.tail = nil
  end
  self.len = self.len - 1
  return node.value
end

-- Tests

--- @type LinkedList<integer>
local list1 = flib_linked_list.new()
flib_linked_list.push_back(list1, 1)
flib_linked_list.push_back(list1, 2)
flib_linked_list.push_back(list1, 3)
assert(flib_linked_list.pop_front(list1) == 1)
assert(flib_linked_list.pop_back(list1) == 3)
assert(flib_linked_list.pop_back(list1) == 2)
assert(flib_linked_list.pop_back(list1) == nil)

return flib_linked_list
