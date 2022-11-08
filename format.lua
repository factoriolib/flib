--- Various string formatting functions.
--- @module '__flib__.format'
local flib_format = {}

--- Format a number for display, adding commas and an optional suffix.
--- @param amount number The number to format
--- @param append_suffix boolean? If true, the number will be shortened and an SI suffix will be added to the end.
--- @return string
function flib_format.number(amount, append_suffix)
  local suffix = ""
  if append_suffix then
    local suffix_list = {
      ["Y"] = 1e24, -- yotta
      ["Z"] = 1e21, -- zetta
      ["E"] = 1e18, -- exa
      ["P"] = 1e15, -- peta
      ["T"] = 1e12, -- tera
      ["G"] = 1e9, -- giga
      ["M"] = 1e6, -- mega
      ["k"] = 1e3, -- kilo
    }
    for letter, limit in pairs(suffix_list) do
      if math.abs(amount) >= limit then
        amount = math.floor(amount / (limit / 10)) / 10
        suffix = letter
        break
      end
    end
    -- TODO: Fixed precision format
  end
  local formatted, k = tostring(amount), nil
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    if k == 0 then
      break
    end
  end
  return formatted .. suffix
end

--- Convert the given tick or game.tick into "[hh:]mm:ss" format.
--- @param tick uint? default: `game.tick`
--- @param include_leading_zeroes boolean? If true, leading zeroes will be
--- included in single-digit minute and hour values.
--- @return string
function flib_format.time(tick, include_leading_zeroes)
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

return flib_format
