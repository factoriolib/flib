local flib_linked_list = require("linked-list")

--- @type LinkedList<integer>
local list1 = flib_linked_list.new()
flib_linked_list.push_back(list1, 1)
flib_linked_list.push_back(list1, 2)
flib_linked_list.push_back(list1, 3)
assert(flib_linked_list.pop_front(list1) == 1)
assert(flib_linked_list.pop_back(list1) == 3)
assert(flib_linked_list.pop_back(list1) == 2)
assert(flib_linked_list.pop_back(list1) == nil)
