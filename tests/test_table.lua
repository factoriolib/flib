local Test = require('tests.factorio_luaunit')
local flib_table = require('__flib__.table')

function Test_flib_table_has_table()
  for k, v in pairs(table) do Test.assertEquals(flib_table[k], v) end
end

local table = flib_table

function Test_partial_sort()
  -- Has vararg
end

function Test_deep_merge()
end

function Test_invert()
  local invert
  local array = { 'one', 'two', 'three', 'four' }
  local dict = { one = 1, two = 2, three = 3, four = 4 }
  invert = table.invert(array)
  Test.assertItemsEquals(invert, dict)
  Test.assertEquals(#array, 4)
  invert = table.invert(invert)
  Test.assertEquals(invert, array)
end

function Test_for_each()
  -- Has vararg
end

function Test_splice()
end

function Test_slice()
end

function Test_for_n_of()
  -- Has vararg
end

function Test_size()
  Test.assertEquals(table.size { a = 1, b = 2, c = 3 }, 3)
  Test.assertEquals(table.size { 'one', 'two', 'three' }, 3)
  Test.assertEquals(table.size { 'one', two = 'two', three = true }, 3)
  local silly = { 'one', 'two', three = true }
  silly[2] = nil
  Test.assertEquals(table.size(silly), 2)
end

function Test_shallow_copy()

end

function Test_shallow_merge()
  local a = { b = {}, c = {}, d = 3 }
  local b = table.shallow_copy(a)
  Test.assertNotIs(b, a)
  Test.assertIs(b.b, a.b)
  Test.assertIs(b.c, a.c)
  Test.assertEquals(b.d, 3)
end

function Test_filter()
  -- Has vararg

end

function Test_deep_compare()
end

function Test_array_merge()
  local a = { 'one', 'two' }
  local b = { 'three', 'four' }
  Test.assertEquals(table.array_merge { a, b }, { 'one', 'two', 'three', 'four' })
end

function Test_retrieve()
  local dict = { one = 1, two = 2, three = 3, four = 4 }
  Test.assertEquals(table.retrieve(dict, 'two'), 2)
  Test.assertIsNil(dict['two'])
  Test.assertIsNil(table.retrieve(dict, 'five'))

  local array = { 'one', 'two', 'three', 'four' }
  Test.assertEquals(table.retrieve(array, 2), 'two')
  Test.assertEquals(#array, 4)
  Test.assertIsNil(array[2])
end

function Test_map()
  -- Has vararg
end

function Test_get_or_insert()
  local dict = {a = 1, c = 3, d = 4}
  Test.assertEquals(table.get_or_insert(dict, 'b', 2), 2)
  Test.assertEquals(dict.b, 2)
  Test.assertEquals(table.get_or_insert(dict, 'c', 4), 3)
end

function Test_find()
  Test.assertEquals(table.find({ 'one', 'two', 'three' }, 'two'), 2)
  local a = { one = 'one', two = 'two', three = 'three' }
  Test.assertEquals(table.find(a, 'two'), 'two')
end

function Test_unique_insert()
  local a = { 'one', 'three', 'four' }
  local result = { 'one', 'two', 'three', 'four' }
  local result2 = { 'one', 'two', 'three', 'four', 'five' }
  Test.assertIsTrue(table.unique_insert(a, 2, 'two'))
  Test.assertEquals(a, result)
  Test.assertIsFalse(table.unique_insert(a, 'two'))
  Test.assertIsFalse(table.unique_insert(a, 2, 'two'))
  Test.assertEquals(#result, 4)
  Test.assertIsTrue(table.unique_insert(a, 'five'))
  Test.assertEquals(a, result2)
end

function Test_array_copy()
  local array = { 'one', 'two', 'three' }
  local copy = table.array_copy({ 'one', 'two', 'three' })
  Test.assertEquals(copy, array)
end

function Test_reduce()
  -- has vararg
end

function Test_deep_copy()
end

Test.Run()
