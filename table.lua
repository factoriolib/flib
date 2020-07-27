--- Functions for working with tables.
-- @module table
-- @alias flib_table
-- @usage local table = require('__flib__.table')
local flib_table = {}

-- import lua table functions
for name, func in pairs(table) do
  flib_table[name] = func
end

--- Run `body(value, key)` over `n` items from `tbl`, starting after `from_k`.
--
-- The first return value of each invocation of `body` will be collected and returned in a table keyed by the current item's key.
--
-- The second return value of `body` is a flag requesting deletion of the current item.
--
-- **DO NOT** delete entires from `tbl` from within `body`, this will break the iteration.
---@tparam table tbl The table to iterate over.
---@tparam any|nil from_k The key to start iteration at, or `nil` to start at the beginning of `tbl`. If the key does not exist in `tbl`, it will be treated as `nil`.
---@tparam uint n The number of items to iterate.
---@tparam function body Callback that will be run for each element in `tbl`.
---@tparam[opt] function _next A custom `next()` function. If not provided, the default `next()` will be used.
---@treturn any|nil Where the iteration ended. Can be any valid table key, or `nil` if the end of `tbl` was reached. Pass this as `from_k` in the next call to `for_n_of` for `tbl`.
---@treturn table The results compiled from the first return of `body`.
function table.for_n_of(tbl, from_k, n, body, _next)
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

return flib_table