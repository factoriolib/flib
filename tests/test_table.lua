local Test = require('tests.factorio_luaunit')
local flib_table = require('__flib__.table')

function Test_flib_table_has_table()
  for k, v in pairs(table) do Test.assertEquals(flib_table[k], v) end
end

local table = flib_table

function Test_partial_sort() -- Has vararg
  error()
end

function Test_deep_merge()
  local a = {b1 = {c1 = 1}}
  local b = {b1 = {c2 = 10}}
  local c = {b1 = {c1 = 5}}
  local should = {b1 = { c1 = 5, c2 = 10}}
  Test.assertItemsEquals(table.deep_merge{a, b, c}, should)
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

function Test_for_each() -- Has vararg
  local tbl = {1, 2, 3, 4, 5}

  -- no return
  local count = 0
  local halted = table.for_each(tbl, function(v) count = count + v end)
  Test.assertEquals(count, 15)
  Test.assertNotIsTrue(halted)

  -- returns on even
  count = 0
  halted = table.for_each(tbl, function(v) count = count + 1;return v % 2 == 0 end)
  Test.assertEquals(count, 2)
  Test.assertIsTrue(halted)


  -- vararg no return
  count = 0
  local for_each = function(v, _, n) count = count + n + v end
  halted = table.for_each(tbl, for_each, 10)
  Test.assertEquals(count, 65)
  Test.assertNotIsTrue(halted)

  count = 0
  for_each = function(v, k, n) count = count + k + n ;return v % 2 == 0 end
  count = 0
  halted = table.for_each(tbl, for_each, 10)
  Test.assertEquals(count, 23)
  Test.assertIsTrue(halted)

end

function Test_splice()
  local arr = {10, 20, 30, 40, 50, 60, 70, 80, 90}
  local arr_expected = {10, 20, 80, 90}
  local spliced = table.splice(arr, 3, 7) -- {30, 40, 50, 60, 70}
  Test.assertEquals(spliced, {30, 40, 50, 60, 70})
  Test.assertEquals(arr, arr_expected)
end

function Test_slice()
  local arr = {10, 20, 30, 40, 50, 60, 70, 80, 90}
  local arr_expected = {10, 20, 30, 40, 50, 60, 70, 80, 90}
  local sliced = table.slice(arr, 3, 7) -- {30, 40, 50, 60, 70}
  Test.assertEquals(sliced, {30, 40, 50, 60, 70})
  Test.assertEquals(arr, arr_expected)
end

function Test_for_n_of() -- Has vararg
  local tbl = {}
  local count = 1000
  for _ = 1, 1000 do
    table.insert(tbl, count)
    count = count - 1
  end

  local calc = 0
  local from_k, res, traversed
  from_k, res, traversed = table.for_n_of(tbl, from_k, 10, function(v) calc = calc - v; return v end)
  Test.assertEquals(from_k, 10)
  Test.assertEquals(calc, -9955 )
  Test.assertEquals(#tbl, 1000)
  Test.assertEquals(#res, 10)
  Test.assertIsFalse(traversed)

  res = nil
  from_k, res, traversed = table.for_n_of(tbl, 995, 10, function(v) calc = calc - v; return v end)
  Test.assertEquals(#tbl, 1000)
  Test.assertEquals(table_size(res), 5)
  Test.assertIsTrue(traversed)
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
  local c1, c2 = {}, {}
  local a = {c1 = c1, c2 = c2, d = 3}
  local shallow = table.shallow_copy(a)
  Test.assertNotIs(shallow, a)
  Test.assertIs(shallow.c1, c1)
  Test.assertIs(shallow.c2, c2)
  Test.assertEquals(shallow.d, 3)
end

function Test_shallow_merge()
  local a = { b = {}, c = {}, d = 3 }
  local b = table.shallow_copy(a)
  Test.assertNotIs(b, a)
  Test.assertIs(b.b, a.b)
  Test.assertIs(b.c, a.c)
  Test.assertEquals(b.d, 3)
end

function Test_filter() -- Has vararg
  local tbl = {1, 2, 3, 4, 5, 6}
  local just_evens = table.filter(tbl, function(v) return v % 2 == 0 end) -- {[2] = 2, [4] = 4, [6] = 6}
  Test.assertItemsEquals(just_evens, {[2] = 2, [4] = 4, [6] = 6})
  local just_evens_arr = table.filter(tbl, function(v) return v % 2 == 0 end, true) -- {2, 4, 6}
  Test.assertEquals(just_evens_arr, {2, 4, 6})
end

function Test_deep_compare()
  local a = { b1 = {c1 = {d1 = 3}} }
  local b = a
  local c = { b1 = {c1 = {d1 = 3}} }
  local d = { b1 = {c1 = {d1 = 4}} }
  local e = { b1 = {c1 = {d1 = 3, d2 = 1}} }

  Test.assertIsTrue(table.deep_compare(a, b))
  Test.assertIsTrue(table.deep_compare(a, c))
  Test.assertIsFalse(table.deep_compare(a, d))
  Test.assertIsFalse(table.deep_compare(a, e))

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

function Test_map() -- Has vararg
  local tbl = {1, 2, 3, 4, 5}
  local tbl_times_ten = table.map(tbl, function(v) return v * 10 end) -- {10, 20, 30, 40, 50}
  Test.assertEquals(tbl_times_ten, {10, 20, 30, 40, 50})

  local mapper = function(v, _, n)
    return v * n
  end
  local tbl_map = table.map(tbl, mapper, 100)
  Test.assertEquals(tbl_map, {100, 200, 300, 400, 500})
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

function Test_reduce() -- has vararg
  local tbl = {10, 20, 30, 40, 50}
  local sum = table.reduce(tbl, function(acc, v) return acc + v end)
  Test.assertEquals(sum, 150)

  local sum_minus_ten = table.reduce(tbl, function(acc, v) return acc + v end, -10)
  Test.assertEquals(sum_minus_ten, 140)

  local sum_minus_something = table.reduce(tbl, function(acc, v, n) return acc + v - n end, -10, 1)
  Test.assertEquals(sum_minus_something, 125)
end

function Test_deep_copy()
  local a = { b1 = {c1 = {d1 = 3}} }
  local b = table.deep_copy(a)

  Test.assertNotIs(a, b)
  Test.assertNotIs(a.b1, b.b1)
  Test.assertNotIs(a.b1.c1, b.b1.c1)
  Test.assertEquals(a.b1.c1.d1, b.b1.c1.d1)
end

Test.Run()
