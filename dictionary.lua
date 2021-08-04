local flib_dictionary = {}

local inner_separator = "⤬"
local separator = "⤬⤬⤬"
local max_depth = 5

local function kv(key, value)
  return key..inner_separator..value..separator
end

-- TODO: If we're storing the dictionaries in `global` ourselves, do we really need the Dictionary object?

local Dictionary = {}

function Dictionary:add(key, value)
  local to_add = {"", key, inner_separator, value, separator}

  local ref = self.ref
  local i = self.i + 1
  if i < 20 then
    ref[i] = to_add
    self.i = i
  else
    local r_i = self.r_i + 1
    if r_i <= max_depth then
      local new_level = {"", to_add}
      ref[i] = new_level
      self.ref = new_level
      self.i = 2
      self.r_i = r_i
    else
      local s_i = self.s_i + 1
      self.s_i = s_i
      local new_set = {"", self:get_starting_key()}
      self.ref = new_set
      self.strings[s_i] = new_set
      self.i = 2
      self.r_i = 1
    end
  end
end

--- Initialize the module's script data table.
-- Must be called at the beginning of `on_init` and during `on_configuration_changed` to reset all ongoing translations.
function flib_dictionary.init()
  if not global.__flib then
    global.__flib = {}
  end
  global.__flib.dictionary = {players = {}, raw = {}, translated = {}}
end

--- Create a new dictionary.
function flib_dictionary.new(name, keep_untranslated, initial_contents)
  if global.__flib.dictionary.raw[name] then
    error("Dictionary with the name `"..name.."` already exists.")
  end

  local initial_string = {""}
  local self = setmetatable(
    {
      -- Indices
      i = 2,
      r_i = 1,
      s_i = 1,
      -- Internal
      -- `ref` can't exist until after this table is initially created
      ref = initial_string,
      strings = {initial_string},
      -- Settings
      keep_untranslated = keep_untranslated,
      -- Meta
      name = name,
    },
    {__index = Dictionary}
  )

  for key, value in pairs(initial_contents or {}) do
    self:add(key, value)
  end

  global.__flib.dictionary.raw[name] = self

  return self
end

function flib_dictionary.translate(player)
  -- TODO:
end

function flib_dictionary.on_tick(event_data)

end

local dictionary_match_string = kv("^FLIB_DICTIONARY_NAME", "(.-)")
  ..kv("FLIB_DICTIONARY_NAME", "(.-)")
  ..kv("FLIB_DICTIONARY_STRING_INDEX", "%d-")
  .."(.*)$"

function flib_dictionary.handle_translation(event_data)
  if event_data.translated and string.find(event_data.result, "^FLIB_DICTIONARY_TRANSLATION") then
    local _, _, dict_name, dict_lang, string_index, translation = string.find(
      event_data.result,
      dictionary_match_string
    )

    if dict_name and dict_lang and string_index and translation then
      local language_dictionaries = global.__flib.dictionary.translated[dict_lang]
      -- In some cases, this can fire before on_configuration_changed
      if not language_dictionaries then return end
      local dictionary = language_dictionaries[dict_lang]
      if not dictionary then return end
      local dict_data = global.__flib.dictionary.raw[dict_name]

      for str in string.gmatch(event_data.result, "(.-)"..separator) do
        local _, _, key, value = string.find(translation, "^(.-)"..inner_separator.."(.-)$")
        if key then
          -- If `keep_untranslated` is true, then use the key as the value if it failed
          local failed = string.find(value, "Unknown key:")
          if failed and dict_data.keep_untranslated then
            value = key
          elseif failed then
            value = nil
          end
          if value then
            dictionary[key] = value
          end
        end
      end
    end
  end
end

return flib_dictionary
