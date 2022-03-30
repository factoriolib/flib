--- Miscellaneous control-stage functions that don't yet have a proper home.
local flib_misc = {}

local math = math
local string = string

--- Calculate the distance in tiles between two positions.
--- @param pos1 MapPosition
--- @param pos2 MapPosition
--- @return number
function flib_misc.get_distance(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local y1 = pos1.y or pos1[2]
  local x2 = pos2.x or pos2[1]
  local y2 = pos2.y or pos2[2]
  return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

--- Calculate the squared distance in tiles between two positions.
--- @param pos1 MapPosition
--- @param pos2 MapPosition
--- @return number
function flib_misc.get_distance_squared(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local y1 = pos1.y or pos1[2]
  local x2 = pos2.x or pos2[1]
  local y2 = pos2.y or pos2[2]
  return (x1 - x2) ^ 2 + (y1 - y2) ^ 2
end

--- Convert given tick or game.tick into "[hh:]mm:ss" format.
--- @param tick number? default: `game.tick`
--- @param include_leading_zeroes boolean? If true, leading zeroes will be included in single-digit minute and hour values.
--- @return string
function flib_misc.ticks_to_timestring(tick, include_leading_zeroes)
  local total_seconds = math.floor((tick or game.ticks_played) / 60)
  local seconds = total_seconds % 60
  local minutes = math.floor(total_seconds / 60)
  if minutes > 59 then
    minutes = minutes % 60
    local hours = math.floor(total_seconds / 3600)
    if include_leading_zeroes then
      return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    else
      return string.format("%d:%02d:%02d", hours, minutes, seconds)
    end
  else
    if include_leading_zeroes then
      return string.format("%02d:%02d", minutes, seconds)
    else
      return string.format("%d:%02d", minutes, seconds)
    end
  end
end

--- Split numerical values by a delimiter.
---
--- Adapted from [lua-users.org](http://lua-users.org/wiki/FormattingNumbers).
--- @param number number
--- @param delimiter string default: `","`
--- @return string
function flib_misc.delineate_number(number, delimiter)
  delimiter = delimiter or ","
  -- Handle decimals
  local _, _, before, after = string.find(number, "^(%d*)(%.%d*)")
  if before and after then
    number = tonumber(before)
    after = after
  else
    before = math.floor(number)
    after = ""
  end
  local formatted = before
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1" .. delimiter .. "%2")
    if k == 0 then
      break
    end
  end
  return formatted .. after
end

return flib_misc
