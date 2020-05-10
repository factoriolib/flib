--- defines reverse lookup table
-- @usage local reverse_defines = require('__flib__.reverse_defines')

local reverse_defines = {}

local function build_reverse_defines(lookup_table, base_table)
  lookup_table = lookup_table or {}
  for k, v in pairs(base_table) do
    if type(v) == "table" then
      lookup_table[k] = {}
      build_reverse_defines(lookup_table[k], v)
    else
      lookup_table[v] = k
    end
  end
end

build_reverse_defines(reverse_defines, defines)

return reverse_defines
