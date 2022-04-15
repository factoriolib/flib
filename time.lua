--- Functions and properties for dealing with ticks.
--- @class flib_time
local flib_time = {}

flib_time.second = 60
flib_time.minute = 3600
flib_time.hour = 216000
flib_time.day = 5184000

--- Convert given tick or game.tick into "[hh:]mm:ss" format.
--- @param tick number? default: `game.tick`
--- @param include_leading_zeroes boolean? If true, leading zeroes will be included in single-digit minute and hour values.
--- @return string
function flib_time.ticks_to_timestring(tick, include_leading_zeroes)
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

return flib_time
