local event = require("__flib__.event")
local table = require("__flib__.table")

local flib_dictionary = {}

local inner_separator = "⤬"
local separator = "⤬⤬⤬"
local max_depth = 15

local on_language_translated = event.generate_id()

local function kv(key, value)
  return key..inner_separator..value..separator
end

-- Dictionary object (for setup)

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
      self.i = 1
      self.r_i = r_i
    else
      local s_i = self.s_i + 1
      self.s_i = s_i
      local new_set = {""}
      self.ref = new_set
      self.strings[s_i] = new_set
      self.i = 1
      self.r_i = 1
    end
  end
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
      i = 1,
      r_i = 1,
      s_i = 1,
      -- Internal
      ref = initial_string,
      strings = {initial_string},
      -- Meta
      name = name,
      -- To prevent saving in `global`
      __nosave = game.players,
    },
    {__index = Dictionary}
  )

  for key, value in pairs(initial_contents or {}) do
    self:add(key, value)
  end

  global.__flib.dictionary.raw[name] = {strings = self.strings, keep_untranslated = keep_untranslated}

  return self
end

-- Module functions

--- Initialize the module's script data table.
-- Must be called at the beginning of `on_init` and during `on_configuration_changed` to reset all ongoing translations.
function flib_dictionary.init()
  if not global.__flib then
    global.__flib = {}
  end
  global.__flib.dictionary = {
    in_process = {},
    players = {},
    raw = {},
    translated = {}
  }
end

-- Add the player to the table and request the translation for their language code
function flib_dictionary.translate(player)
  local player_table = global.__flib.dictionary.players[player.index]
  if player_table then
    error("Player `"..player.name.."` ["..player.index.."] is already translating!")
  end

  global.__flib.dictionary.players[player.index] = {
    player = player,
    status = "get_language",
  }

  player.request_translation({"", "FLIB_LOCALE_IDENTIFIER", separator, {"locale-identifier"}})
end

function flib_dictionary.iterate(event_data)
  local script_data = global.__flib.dictionary
  for player_index, player_table in pairs(script_data.players) do
    if player_table.status == "translating" then
      local i = player_table.i
      local strings = script_data.raw[player_table.dictionary].strings
      local string = strings[i]
      if string then
        player_table.player.request_translation{
          "",
          kv("FLIB_DICTIONARY_NAME", player_table.dictionary),
          kv("FLIB_DICTIONARY_LANGUAGE", player_table.language),
          kv("FLIB_DICTIONARY_STRING_INDEX", i),
          string,
        }
        player_table.i = i + 1
        if not strings[i + 1] then
          local next_dictionary = next(script_data.raw, player_table.dictionary)
          if next_dictionary then
            player_table.dictionary = next_dictionary
            player_table.i = 1
          else
            -- TODO: Handle edge case with missing translations when saving/loading a singleplayer game
            player_table.status = "finishing"
          end
        end
      end
    end
  end
end

local dictionary_match_string = kv("^FLIB_DICTIONARY_NAME", "(.-)")
  ..kv("FLIB_DICTIONARY_LANGUAGE", "(.-)")
  ..kv("FLIB_DICTIONARY_STRING_INDEX", "(%d-)")
  .."(.*)$"

function flib_dictionary.handle_translation(event_data)
  if not event_data.translated then return end
  local script_data = global.__flib.dictionary
  if string.find(event_data.result, "^FLIB_DICTIONARY_NAME") then
    local _, _, dict_name, dict_lang, string_index, translation = string.find(
      event_data.result,
      dictionary_match_string
    )

    if dict_name and dict_lang and string_index and translation then
      -- TODO: Add this to a list so we know which strings were actually translated
      -- Alternatively, investigate using `on_load` hax in singleplayer to restart translations and avoid the skipping
      string_index = tonumber(string_index)
      local language_data = script_data.in_process[dict_lang]
      -- In some cases, this can fire before on_configuration_changed
      if not language_data then return end
      local dictionary = language_data.dictionaries[dict_name]
      if not dictionary then return end
      local dict_data = script_data.raw[dict_name]

      for str in string.gmatch(translation, "(.-)"..separator) do
        local _, _, key, value = string.find(str, "^(.-)"..inner_separator.."(.-)$")
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

      local player_table = script_data.players[event_data.player_index]
      if player_table.status == "finishing" then
        -- We're done!
        script_data.translated[dict_lang] = language_data.dictionaries
        script_data.in_process[dict_lang] = nil
        script_data.players[event_data.player_index] = nil
        event.raise(on_language_translated, {
          dictionaries = language_data.dictionaries,
          language = dict_lang,
          players = dict_data.players,
        })
      end
    end
  elseif string.find(event_data.result, "^FLIB_LOCALE_IDENTIFIER") then
    local _, _, language = string.find(event_data.result, "^FLIB_LOCALE_IDENTIFIER"..separator.."(.*)$")
    if language then
      local player_table = script_data.players[event_data.player_index]
      if not player_table then return end

      player_table.language = language

      -- Check if this language is already translated or being translated
      local dictionaries = script_data.translated[language]
      if dictionaries then
        script_data.players[event_data.player_index] = nil
        event.raise(
          on_language_translated,
          {dictionaries = dictionaries, language = language, players = {event_data.player_index}}
        )
        return
      end
      local in_process = script_data.in_process[language]
      if in_process then
        table.insert(in_process.players, event_data.player_index)
        player_table.status = "waiting"
        return
      end

      -- Start translating this language
      player_table.status = "translating"
      player_table.dictionary = next(script_data.raw)
      player_table.i = 1

      script_data.in_process[language] = {
        dictionaries = table.map(script_data.raw, function(_) return {} end),
        players = {event_data.player_index}
      }
    end
  end
end

flib_dictionary.on_language_translated = on_language_translated

return flib_dictionary
