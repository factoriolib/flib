local event = require("__flib__.event")
local table = require("__flib__.table")

local flib_dictionary = {}

local inner_separator = "⤬"
local separator = "⤬⤬⤬"
local max_depth = 15
local translation_timeout = 180

local on_language_translated = event.generate_id()

-- Holds the raw dictionaries
local raw = {}

local use_local_storage = false

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
      self.i = 2
      self.r_i = r_i
    else
      local s_i = self.s_i + 1
      self.s_i = s_i
      local new_set = {"", to_add}
      self.ref = new_set
      self.strings[s_i] = new_set
      self.i = 2
      self.r_i = 1
    end
  end
end

--- Create a new dictionary.
function flib_dictionary.new(name, keep_untranslated, initial_contents)
  if raw[name] then
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
    },
    {__index = Dictionary}
  )

  for key, value in pairs(initial_contents or {}) do
    self:add(key, value)
  end

  raw[name] = {strings = self.strings, keep_untranslated = keep_untranslated}

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
  if use_local_storage then
    raw = {}
  else
    raw = global.__flib.dictionary.raw
  end
end

function flib_dictionary.load()
  -- TODO: Upvalue `script_data` as well
  if not use_local_storage then
    raw = global.__flib.dictionary.raw
  end
end

-- Add the player to the table and request the translation for their language code
function flib_dictionary.translate(player)
  local player_data = global.__flib.dictionary.players[player.index]
  if player_data then return end

  global.__flib.dictionary.players[player.index] = {
    player = player,
    status = "get_language",
  }

  player.request_translation({"", "FLIB_LOCALE_IDENTIFIER", separator, {"locale-identifier"}})
end

local function request_translation(player_data)
  local string = raw[player_data.dictionary].strings[player_data.i]

  -- We use `while` instead of `if` here just in case a dictionary doesn't have any strings in it
  while not string do
    local next_dictionary = next(raw, player_data.dictionary)
    if next_dictionary then
      -- Set the next dictionary and reset index
      player_data.dictionary = next_dictionary
      player_data.i = 1
      string = raw[next_dictionary].strings[1]
    else
      -- We're done!
      player_data.status = "finished"
      return
    end
  end

  player_data.player.request_translation{
    "",
    kv("FLIB_DICTIONARY_NAME", player_data.dictionary),
    kv("FLIB_DICTIONARY_LANGUAGE", player_data.language),
    kv("FLIB_DICTIONARY_STRING_INDEX", player_data.i),
    string,
  }

  player_data.requested_tick = game.tick
end

function flib_dictionary.check_skipped()
  local script_data = global.__flib.dictionary
  local tick = game.tick
  for _, player_data in pairs(script_data.players) do
    -- If it's been longer than the timeout, request the string again
    -- This is to solve a very rare edge case where translations requested on the same tick that a singleplayer game
    -- is saved will not be returned when that save is loaded
    if player_data.status == "translating" and player_data.requested_tick + translation_timeout <= tick then
      request_translation(player_data)
    end
  end
end

local dictionary_match_string = kv("^FLIB_DICTIONARY_NAME", "(.-)")
  ..kv("FLIB_DICTIONARY_LANGUAGE", "(.-)")
  ..kv("FLIB_DICTIONARY_STRING_INDEX", "(%d-)")
  .."(.*)$"

function flib_dictionary.process_translation(event_data)
  if not event_data.translated then return end
  local script_data = global.__flib.dictionary
  if string.find(event_data.result, "^FLIB_DICTIONARY_NAME") then
    local _, _, dict_name, dict_lang, string_index, translation = string.find(
      event_data.result,
      dictionary_match_string
    )

    if dict_name and dict_lang and string_index and translation then
      local language_data = script_data.in_process[dict_lang]
      -- In some cases, this can fire before on_configuration_changed
      if not language_data then return end
      local dictionary = language_data.dictionaries[dict_name]
      if not dictionary then return end
      local dict_data = raw[dict_name]
      local player_data = script_data.players[event_data.player_index]

      -- If this number does not match, this is a duplicate, so ignore it
      if tonumber(string_index) == player_data.i then
        -- Extract current string's translations
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

        -- Request next translation
        player_data.i = player_data.i + 1
        request_translation(player_data)

        if player_data.status == "finished" then
          -- We're done!
          script_data.translated[dict_lang] = language_data.dictionaries
          script_data.in_process[dict_lang] = nil
          for _, player_index in pairs(language_data.players) do
            script_data.players[player_index] = nil
          end
          event.raise(on_language_translated, {
            dictionaries = language_data.dictionaries,
            language = dict_lang,
            players = language_data.players,
          })
        end
      end
    end
  elseif string.find(event_data.result, "^FLIB_LOCALE_IDENTIFIER") then
    local _, _, language = string.find(event_data.result, "^FLIB_LOCALE_IDENTIFIER"..separator.."(.*)$")
    if language then
      local player_data = script_data.players[event_data.player_index]
      if not player_data then return end

      player_data.language = language

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
        player_data.status = "waiting"
        return
      end

      -- Set up player data for translating
      player_data.status = "translating"
      player_data.dictionary = next(raw)
      player_data.i = 1

      -- Add language to in process data
      script_data.in_process[language] = {
        dictionaries = table.map(raw, function(_) return {} end),
        players = {event_data.player_index}
      }

      -- Start translating
      request_translation(player_data)
    end
  end
end

function flib_dictionary.cancel_translation(player_index)
  local script_data = global.__flib.dictionary
  local player_data = script_data.players[player_index]
  if player_data then
    if player_data.status == "translating" then
      local in_process = script_data.in_process[player_data.language]
      if not in_process then error("Dafuq?") end
      if #in_process.players > 1 then
        -- Copy progress to another player with the same language
        local first_player = in_process.players[1]
        local first_player_data = script_data.players[first_player]
        first_player_data.status = "translating"
        first_player_data.dictionary = player_data.dictionary
        first_player_data.i = player_data.i

        -- Resume translating with the new player
        request_translation(first_player_data)
      else
        -- Completely cancel the translation
        script_data.in_process[player_data.language] = nil
      end
    elseif player_data.status == "waiting" then
      local in_process = script_data.in_process[player_data.language]
      -- Remove this player from the players table
      for i, pi in pairs(in_process.players) do
        if pi == player_index then
          table.remove(in_process.players, i)
          break
        end
      end
    end

    -- Delete this player's data
    script_data.players[player_index] = nil
  end
end

function flib_dictionary.set_use_local_storage(value)
  use_local_storage = value
end

flib_dictionary.on_language_translated = on_language_translated

return flib_dictionary
