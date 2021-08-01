local flib_dictionary = {}

local Dictionary = {}

local inner_separator = "⤬"
local separator = "⤬⤬⤬"
local max_depth = 20

--[[
  LOGIC:
  - Each level will have 18 strings (17 in the first level, since the first one has to be the dictionary name)
  - After ten strings, the eleventh string will be a new level
  - There are 20 levels in each whole string
]]

function Dictionary:add(key, value)
  local to_add = {"", key, inner_separator, value, separator}

  local ref = self.ref
  local i = self.i + 1
  if i < 20 then
    ref[i] = to_add
    self.i = i
  else
    local r_i = self.r_i + 1
    if r_i <= 20 then
      local new_level = {"", to_add}
      ref[i] = new_level
      self.ref = new_level
      self.i = 2
      self.r_i = r_i
    else
      local s_i = self.s_i + 1
      local new_set = {"", self.starting_key}
      self.ref = new_set
      self.strings[s_i] = new_set
      self.i = 2
      self.r_i = 1
      self.s_i = s_i
    end
  end
end

function flib_dictionary.new(name, initial_contents)
  local starting_key = "FLIB_TRANSLATION_DICTIONARY"..inner_separator..name..separator
  local starting_string = {"", starting_key}
  local self = setmetatable(
    {
      starting_key = starting_key,
      strings = {starting_string},
      i = 2,
      r_i = 1,
      s_i = 1,
      ref = starting_string
    },
    {__index = Dictionary}
  )
  for key, value in pairs(initial_contents or {}) do
    self:add(key, value)
  end
  return self
end

return flib_dictionary
