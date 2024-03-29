if ... ~= "__flib__.reverse-defines" then
  return require("__flib__.reverse-defines")
end

--- Defines reverse lookup table.
---
--- NOTE: Type intellisense simply does not work for this module, and there is no easy way to fix
--- it. Use of this module is discouraged.
---
--- # Example
---
--- ```lua
--- event.on_built_entity(function(e)
---   local player = game.get_player(e.player_index)
---   local controller_name = reverse_defines.controllers[player.controller_type]
--- end)
--- ```
local flib_reverse_defines = {}

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

build_reverse_defines(flib_reverse_defines, defines)

return flib_reverse_defines
