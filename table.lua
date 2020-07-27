--- Functions for working with arrays and tables.
--
-- Extends the [Lua 5.2 table library](https://www.lua.org/manual/5.2/manual.html#6.5). As such, all functions available
-- there are also available here.
--
-- **NOTE:** Several functions in this module will only work with [arrays](https://www.lua.org/pil/11.1.html), which are
-- tables with sequentially numbered keys. All table functions will work with arrays as well, but array functions
-- **will not** work with tables.
-- @module table
-- @alias flib_table
-- @usage local table = require('__flib__.table')
local flib_table = {}

-- import lua table functions
for name, func in pairs(table) do
  flib_table[name] = func
end

--- Recursively compare two tables for inner equality.
--
-- Does not compare metatables.
-- @tparam table tbl1
-- @tparam table tbl2
-- @treturn boolean If the tables are the same.
function flib_table.deep_compare(tbl1, tbl2)
  if tbl1 == tbl2 then return true end
  for k, v in pairs( tbl1 ) do
    if  type(v) == "table" and type(tbl2[k]) == "table" then
      if not flib_table.deep_compare( v, tbl2[k] )  then return false end
    else
      if ( v ~= tbl2[k] ) then return false end
    end
  end
  for k, v in pairs( tbl2 ) do
    if tbl1[k] == nil then return false end
  end
  return true
end

--- Recursively copy the contents of a table into a new table.
--
-- Does not create new copies of Factorio objects.
-- @tparam table tbl The table to make a copy of.
-- @treturn table The copied table.
function flib_table.deep_copy(tbl)
  local lookup_table = {}
  local function _copy(object)
    if type(object) ~= "table" then
      return object
    -- don't copy factorio rich objects
    elseif object.__self then
      return object
    elseif lookup_table[object] then
      return lookup_table[object]
    end

    local new_table = {}
    lookup_table[object] = new_table
    for index, value in pairs(object) do
      new_table[_copy(index)] = _copy(value)
    end

    return setmetatable(new_table, getmetatable(object))
  end
  return _copy(tbl)
end

--- Recursively merge two or more tables.
--
-- Values from earlier tables are overwritten by values from later tables, unless both values are tables, in which case
-- they are recursively merged.
--
-- Non-merged tables are deep-copied, so the result is brand-new.
-- @tparam array tables An array of tables to merge.
-- @treturn table The merged tables.
function flib_table.deep_merge(tables)
  local output = {}
  for _, tbl in ipairs(tables) do
    for k, v in pairs(tbl) do
      if (type(v) == "table") then
        if (type(output[k] or false) == "table") then
          output[k] = flib_table.merge{output[k], v}
        else
          output[k] = table.deepcopy(v)
        end
      else
        output[k] = v
      end
    end
  end
  return output
end

--- Call the given function for each item in the table.
--
-- If the callback returns a truthy value, iteration is aborted.
-- @tparam table tbl
-- @tparam function callback Receives `value` and `key` as parameters.
-- @treturn table The table where the callback has been applied to its elements.
function flib_table.for_each(tbl, callback)
  for k, v in pairs(tbl) do
    if callback(v, k) then
      break
    end
  end
  return tbl
end

--- Call the given function on a set number of items in a table, returning the next starting key and the results of the
-- callback.
--
-- Calls `callback(value, key)` over `n` items from `tbl`, starting after `from_k`.
--
-- The first return value of each invocation of `callback` will be collected and returned in a table keyed by the
-- current item's key.
--
-- The second return value of `callback` is a flag requesting deletion of the current item.
--
-- **DO NOT** delete entires from `tbl` from within `callback`, this will break the iteration. Use the deletion flag
-- return instead.
---@tparam table tbl The table to iterate over.
---@tparam any|nil from_k The key to start iteration at, or `nil` to start at the beginning of `tbl`. If the key does
-- not exist in `tbl`, it will be treated as `nil`.
---@tparam uint n The number of items to iterate.
---@tparam function callback Receives `value` and `key` parameters.
---@tparam[opt] function _next A custom `next()` function. If not provided, the default `next()` will be used.
---@treturn any|nil Where the iteration ended. Can be any valid table key, or `nil` if the end of `tbl` was reached.
-- Pass this as `from_k` in the next call to `for_n_of` for `tbl`.
---@treturn table The results compiled from the first return of `callback`.
function flib_table.for_n_of(tbl, from_k, n, callback, _next)
  -- allow non-default `next` function
  -- use `next` if unspecified
  if not _next then _next = next end

  -- verify start key exists, else start from scratch
  if from_k and not tbl[from_k] then
    from_k = nil
  end
  local delete
  local prev
  local result = {}

  -- run `n` times
  for _ = 1, n, 1 do
    local v
    if not delete then
      prev = from_k
    end
    from_k, v = _next(tbl, from_k)
    if delete then
      tbl[delete] = nil
    end

    if v then
      result[from_k],delete = callback(v, from_k)
      if delete then
        delete = from_k
      end
    else
      return from_k,result
    end
  end

  if delete then
    tbl[delete] = nil
    from_k = prev
  end
  return from_k, result
end

--- Filter a table based on the result of a filter function.
--
-- Calls `filter(value, key)` on each element in the table, returning a new table with only pairs for which
-- `filter` returned a truthy value.
-- @tparam table tbl
-- @tparam function filter Takes in `value` and `key` as parameters.
-- @treturn table A new table containing only the filtered values.
function flib_table.filter(tbl, filter)
  local output = {}
  for k, v in pairs(tbl) do
    if filter(v, k) then
      output[k] = v
    end
  end
  return output
end

--- Invert the given table such that `[value] = key`.
--
-- Non-unique values are overwritten based on the ordering from `pairs()`.
-- @tparam table tbl
-- @treturn table The inverted table.
function flib_table.invert(tbl)
  local inverted = {}
  for k, v in pairs(tbl) do
    inverted[v] = k
  end
  return inverted
end

--- Create a transformed table using the output of a mapper function.
--
-- Calls `mapper(value, key)` on each element in the table, using the return as the new value for the key.
-- @tparam table tbl
-- @tparam function mapper Takes in `value` and `key` as parameters.
-- @treturn table A new table containing the transformed values.
function flib_table.map(tbl, mapper)
  local output = {}
  for k, v in pairs(tbl) do
    output[k] = mapper(v, k)
  end
  return output
end

--- "Reduce" an array's values into a single output value, using the results of a reducer function.
--
-- Calls `reducer(accumulator, value, index)` on each element in the array, returning a single accumulated output value.
-- @tparam array arr
-- @tparam function reducer
-- @tparam[opt] any initial_value The initial value for the accumulator. If not provided or is falsy, the first value in
-- the array will be used as the initial `accumulator` value and skipped as `index`. Calling `reduce()` on an empty
-- array without an `initial_value` will cause a crash.
-- @treturn any The accumulated value.
function flib_table.reduce(arr, reducer, initial_value)
  local accumulator = initial_value or arr[1]
  for i = (initial_value and 1 or 2), #arr do
    accumulator = reducer(accumulator, arr[i], i)
  end
  return accumulator
end

--- Shallowly copy the contents of a table into a new table.
--
-- The parent table will have a new table reference, but any subtables within it will still have the same table
-- reference.
-- @tparam table tbl
-- @tparam boolean use_rawset Use rawset to set the values (ignores .__index metamethod).
-- @treturn table The copied table.
function flib_table.shallow_copy(tbl, use_rawset)
  local output = {}
  for k, v in pairs(tbl) do
    if use_rawset then
      rawset(tbl, k, v)
    else
      output[k] = v
    end
  end
  return output
end

--- Retrieve the size of a table.
-- @function size
--
-- Uses Factorio's built-in `table_size` function.
-- @tparam table tbl
-- @treturn uint Size of the table.
flib_table.size = table_size

--- Retrieve a shallow copy of a portion of an array, selected from `start` to `end` inclusive.
--
-- The original array **will not** be modified.
-- @tparam array arr
-- @tparam[opt=1] int start
-- @tparam[opt=#arr] int stop Stop at this index. If negative, will stop `n` items from the end of the array.
-- @treturn array A new array with the copied values.
function flib_table.slice(arr, start, stop)
  local output = {}
  local n = #arr

  start = start or 1
  stop = stop or n
  stop = stop < 0 and (n + stop + 1) or stop

  if start < 1 or start > n then
    return {}
  end

  local k = 1
  for i = start, stop do
    output[k] = arr[i]
    k = k + 1
  end
  return output
end

--- Extract a portion of an array, selected from `start` to `end` inclusive.
--
-- The original array **will** be modified.
-- @tparam array arr
-- @tparam[opt=1] int start
-- @tparam[opt=#arr] int stop Stop at this index. If negative, will stop `n` items from the end of the array.
-- @treturn array A new array with the extracted values.
function flib_table.splice(arr, start, stop)
  local output = {}
  local n = #arr

  start = start or 1
  stop = stop or n
  stop = stop < 0 and (n + stop + 1) or stop

  if start < 1 or start > n then
    return {}
  end

  local k = 1
  for _ = start, stop do
    output[k] = arr[start]
    table.remove(arr, start)
    k = k + 1
  end
  return output
end

return flib_table