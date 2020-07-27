--- Functions for working with arrays and tables.
-- @module table
-- @alias flib_table
-- @usage local table = require('__flib__.table')
local flib_table = {}

-- import lua table functions
for name, func in pairs(table) do
  flib_table[name] = func
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

--- Iterate over a set number of items in a table, returning the next starting key and the results of `body`.
--
-- Runs `body(value, key)` over `n` items from `tbl`, starting after `from_k`.
--
-- The first return value of each invocation of `body` will be collected and returned in a table keyed by the current
-- item's key.
--
-- The second return value of `body` is a flag requesting deletion of the current item.
--
-- **DO NOT** delete entires from `tbl` from within `body`, this will break the iteration.
---@tparam table tbl The table to iterate over.
---@tparam any|nil from_k The key to start iteration at, or `nil` to start at the beginning of `tbl`. If the key does
-- not exist in `tbl`, it will be treated as `nil`.
---@tparam uint n The number of items to iterate.
---@tparam function body Callback that will be run for each element in `tbl`.
---@tparam[opt] function _next A custom `next()` function. If not provided, the default `next()` will be used.
---@treturn any|nil Where the iteration ended. Can be any valid table key, or `nil` if the end of `tbl` was reached.
-- Pass this as `from_k` in the next call to `for_n_of` for `tbl`.
---@treturn table The results compiled from the first return of `body`.
function flib_table.for_n_of(tbl, from_k, n, body, _next)
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
      result[from_k],delete = body(v, from_k)
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

return flib_table