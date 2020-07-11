--- Miscellaneous control-stage functions that don't yet have a proper home.
-- @module misc
-- @alias flib_misc
-- @usage local misc = require("__flib__.misc")
local flib_misc = {}

local math_sqrt = math.sqrt
local math_floor = math.floor
local string_format = string.format
local wire_type = defines.wire_type
local type = type
local tonumber = tonumber

--- Calculate the distance in tiles between two positions.
-- @tparam Concepts.Position pos1
-- @tparam Concepts.Position pos2
-- @treturn double
function flib_misc.get_distance(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local y1 = pos1.y or pos1[2]
  local x2 = pos2.x or pos2[1]
  local y2 = pos2.y or pos2[2]
  return math_sqrt((x1-x2)^2 + (y1-y2)^2)
end

--- Calculate the squared distance in tiles between two positions.
-- @tparam Concepts.Position pos1
-- @tparam Concepts.Position pos2
-- @treturn double
function flib_misc.get_distance_squared(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local y1 = pos1.y or pos1[2]
  local x2 = pos2.x or pos2[1]
  local y2 = pos2.y or pos2[2]
  return (x1-x2)^2 + (y1-y2)^2
end

local format_string_1 = "%d:%02d"
local format_string_2 = "%d:%02d:%02d"

--- Convert given tick or game.tick into "[hh:]mm:ss" format.
-- @tparam[opt=game.tick] uint tick
-- @treturn string
function flib_misc.ticks_to_timestring(tick)
  local total_seconds = math_floor((tick or game.tick)/60)
  local seconds = total_seconds % 60
  local minutes = math_floor(total_seconds/60)
  if minutes > 59 then
    minutes = minutes % 60
    local hours = math_floor(total_seconds/3600)
    return string_format(format_string_2, hours, minutes, seconds)
  else
    return string_format(format_string_1, minutes, seconds)
  end
end

function flib_misc.get_signal_value(entity, signal)
  local red = entity.get_circuit_network(wire_type.red)
  local green = entity.get_circuit_network(wire_type.green)
  local value = 0
  if red then
    value = red.get_signal_value(signal)
  end
  if green then
    value = value + green.get_signal_value(signal)
  end
  return value
end

function flib_misc.check_signal(signal, blacklist_table)
  if type(signal) == "table" then
    local name = signal.name
    local signaltype = signal.type
    if blacklist_table[name] or (signaltype == "fluid" and not game.fluid_prototypes[name]) or (signaltype == "item" and not game.item_prototypes[name]) or signaltype == "virtual" and not game.virtual_signal_prototypes[name] then
      return nil
    end
    return signal
  else
    return nil
  end
end

function flib_misc.color_to_hex(color)
  return string.format("#%.2X%.2X%.2X", color.r or color[1], color.g or color[2], color.b or color[3])
end

function flib_misc.hex_to_color(hex)
  hex = hex:gsub("#", "")
  return {r = tonumber("0x"..hex:sub(1, 2)), g = tonumber("0x"..hex:sub(3, 4)), b = tonumber("0x"..hex:sub(5,6))}
end

return flib_misc