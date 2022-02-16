local table = require("__flib__.table")

--- An easy-to-use dictionary system for storing localised string translations.
local flib_dictionary = {}

local inner_separator = "⤬"
local separator = "⤬⤬⤬"
local max_depth = settings.global["flib-dictionary-levels-per-batch"].value
local translation_timeout = 180

-- Depending on the value of `use_local_storage`, this will be tied to `global` or will be re-generated during `on_load`
local raw = {}

local use_local_storage = false

local function key_value(key, value)
  return key .. inner_separator .. value .. separator
end

--- @class RawDictionary
local RawDictionary = {}

--- Adds a new translation to this dictionary.
---
--- This method **must not** be called after control stage initialization and migration. Doing so will result in
--- different languages having different sets of data.
--- @param internal string An unique, language-agnostic identifier for this translation.
--- @param translation LocalisedString
function RawDictionary:add(internal, translation)
  local to_add = { "", internal, inner_separator, translation, separator }

  local ref = self.ref
  local i = self.i + 1
  if i < 20 then
    ref[i] = to_add
    self.i = i
  else
    local r_i = self.r_i + 1
    if r_i <= max_depth then
      local new_level = { "", to_add }
      ref[i] = new_level
      self.ref = new_level
      self.i = 2
      self.r_i = r_i
    else
      local s_i = self.s_i + 1
      self.s_i = s_i
      local new_set = { "", to_add }
      self.ref = new_set
      self.strings[s_i] = new_set
      self.i = 2
      self.r_i = 1
    end
  end
end

--- Creates a new `RawDictionary`.
---
--- If `keep_untranslated` is `true`, translations that failed (begin with `Unknown key: `) will be added to the dictionary with their internal name as their translated name.
--- @param name string
--- @param keep_untranslated boolean
--- @param initial_contents? table<string, LocalisedString>
--- @return RawDictionary
function flib_dictionary.new(name, keep_untranslated, initial_contents)
  if raw[name] then
    error("Dictionary with the name `" .. name .. "` already exists.")
  end

  local initial_string = { "" }
  local self = setmetatable({
    -- Indices
    i = 1,
    r_i = 1,
    s_i = 1,
    -- Internal
    ref = initial_string,
    strings = { initial_string },
    -- Meta
    name = name,
  }, { __index = RawDictionary })

  for key, value in pairs(initial_contents or {}) do
    self:add(key, value)
  end
  raw[name] = { strings = self.strings, keep_untranslated = keep_untranslated }

  return self
end

--- Initializes the module's script data table.
---
--- Must be called at the **beginning** of `on_init` for initial setup, and at the **beginning** of
--- `on_configuration_changed` to reset all ongoing translations.
function flib_dictionary.init()
  if not global.__flib then
    global.__flib = {}
  end
  global.__flib.dictionary = {
    in_process = {},
    players = {},
    raw = {},
    translated = {},
  }
  if use_local_storage then
    raw = {}
  else
    raw = global.__flib.dictionary.raw
  end
end

--- Sets up the module's local references.
---
--- Must be called at the **beginning** of `on_load`.
---
--- If using `dictionary.set_use_local_storage`, your dictionaries must be re-generated **after** this function is
--- called.
function flib_dictionary.load()
  if not use_local_storage and global.__flib and global.__flib.dictionary then
    raw = global.__flib.dictionary.raw
  end
end

--- Request all dictionaries for the given player.
---
--- The dictionary system stores dictionaries by language, not by player. Thus, if this player's language has already
--- been translated, the module will simply return the already existing dictionaries instead of translating them again.
---
--- If you wish to re-translate dictionaries, call `dictionary.init` and call this function for all online players.
---
--- The player must be connected to the game in order to call this function. Calling this function on a disconnected
--- player will throw an error.
--- @param player LuaPlayer
function flib_dictionary.translate(player)
  if not player.connected then
    error("Player must be connected to the game before this function can be called!")
  end
  local player_data = global.__flib.dictionary.players[player.index]
  if player_data then
    return
  end

  global.__flib.dictionary.players[player.index] = {
    player = player,
    status = "get_language",
    requested_tick = game.tick,
  }

  player.request_translation({ "", "FLIB_LOCALE_IDENTIFIER", separator, { "locale-identifier" } })
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

  player_data.player.request_translation({
    "",
    key_value("FLIB_DICTIONARY_MOD", script.mod_name),
    key_value("FLIB_DICTIONARY_NAME", player_data.dictionary),
    key_value("FLIB_DICTIONARY_LANGUAGE", player_data.language),
    key_value("FLIB_DICTIONARY_STRING_INDEX", player_data.i),
    string,
  })

  player_data.requested_tick = game.tick
end

--- Checks for a skipped translation and re-request it after three seconds.
---
--- Must be called **during** `on_tick`.
---
--- This is to handle a very specific edge-case where translations that are requested on the same tick that a game is
--- saved will not be returned when that save is loaded.
function flib_dictionary.check_skipped()
  local script_data = global.__flib.dictionary
  local tick = game.tick
  for _, player_data in pairs(script_data.players) do
    -- If it's been longer than the timeout, request the string again
    -- This is to solve a very rare edge case where translations requested on the same tick that a singleplayer game
    -- is saved will not be returned when that save is loaded
    if (player_data.requested_tick or 0) + translation_timeout <= tick then
      if player_data.status == "get_language" then
        player_data.player.request_translation({ "", "FLIB_LOCALE_IDENTIFIER", separator, { "locale-identifier" } })
      end
      if player_data.status == "translating" then
        request_translation(player_data)
      end
    end
  end
end

--- Escape match special characters
local function match_literal(s)
  return string.gsub(s, "%-", "%%-")
end

local dictionary_match_string = key_value("^FLIB_DICTIONARY_MOD", match_literal(script.mod_name))
  .. key_value("FLIB_DICTIONARY_NAME", "(.-)")
  .. key_value("FLIB_DICTIONARY_LANGUAGE", "(.-)")
  .. key_value("FLIB_DICTIONARY_STRING_INDEX", "(%d-)")
  .. "(.*)$"

--- Processes a returned translation batch, then request the next batch or return the finished dictionaries.
---
--- Must be called **during** `on_string_translated`.
--- @param event_data on_string_translated
--- @return TranslationFinishedOutput?
function flib_dictionary.process_translation(event_data)
  if not event_data.translated then
    return
  end
  local script_data = global.__flib.dictionary
  if string.find(event_data.result, "FLIB_DICTIONARY_NAME") then
    local _, _, dict_name, dict_lang, string_index, translation = string.find(
      event_data.result,
      dictionary_match_string
    )

    if dict_name and dict_lang and string_index and translation then
      local language_data = script_data.in_process[dict_lang]
      -- In some cases, this can fire before on_configuration_changed
      if not language_data then
        return
      end
      local dictionary = language_data.dictionaries[dict_name]
      if not dictionary then
        return
      end
      local dict_data = raw[dict_name]
      local player_data = script_data.players[event_data.player_index]

      -- If this number does not match, this is a duplicate, so ignore it
      if tonumber(string_index) == player_data.i then
        -- Extract current string's translations
        for str in string.gmatch(translation, "(.-)" .. separator) do
          local _, _, key, value = string.find(str, "^(.-)" .. inner_separator .. "(.-)$")
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
          return { dictionaries = language_data.dictionaries, language = dict_lang, players = language_data.players }
        end
      end
    end
  elseif string.find(event_data.result, "^FLIB_LOCALE_IDENTIFIER") then
    local _, _, language = string.find(event_data.result, "^FLIB_LOCALE_IDENTIFIER" .. separator .. "(.*)$")
    if language then
      local player_data = script_data.players[event_data.player_index]
      -- Handle a duplicate
      if not player_data or player_data.status == "translating" then
        return
      end

      player_data.language = language

      -- Check if this language is already translated or being translated
      local dictionaries = script_data.translated[language]
      if dictionaries then
        script_data.players[event_data.player_index] = nil
        return { dictionaries = dictionaries, language = language, players = { event_data.player_index } }
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
        dictionaries = table.map(raw, function(_)
          return {}
        end),
        players = { event_data.player_index },
      }

      -- Start translating
      request_translation(player_data)
    end
  end
end

--- Cancels the translation of the player's dictionaries if they are the currently translating player.
---
--- If multiple players are waiting on these dictionaries, the translation duties will be handed off to the next player
--- in the list.
---
--- Must be called **during** `on_player_left_game`.
--- @param player_index number
function flib_dictionary.cancel_translation(player_index)
  local script_data = global.__flib.dictionary
  local player_data = script_data.players[player_index]
  if player_data then
    if player_data.status == "translating" then
      local in_process = script_data.in_process[player_data.language]
      if not in_process then
        error("Dafuq?")
      end
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

--- Set whether or not the module is using local storage mode.
---
--- Must be called in the **root scope** of your mod if you wish to use local storage.
---
--- Using local storage is a technique to reduce the amount of script data that the module saves in the `global` table.
--- If you enable this, you **must** re-build all of your dictionaries **during** `on_load`, but **after** calling
--- `dictionary.load`. Failure to do so will result in a desync.
---
--- **Only use this function if you understood the above explanation and if you are familiar with how desyncs can occur.**
---
--- # Examples
---
--- ```lua
--- local dictionary = require("__flib__.dictionary")
--- dictionary.set_use_local_storage(true)
--- ```
--- @param value boolean
function flib_dictionary.set_use_local_storage(value)
  use_local_storage = value
end

--- A "raw" dictionary containing the actual `LocalisedString`s for translation.
---
--- This object **must not** be stored in the `global` table. Doing so will result in a desync if the game is saved and
--- loaded and you attempt to call methods on it.
---
--- # Examples
---
--- ```lua
--- local MyDictionary = dictionary.new("my_dictionary")
--- MyDictionary:add("iron-ore", {"item-name.iron-ore"})
--- ```
--- @class RawDictionary

--- The results of a translated language.
--- @class TranslationFinishedOutput
--- @field language string The language that was translated.
--- @field dictionaries table<string, table<string, string>> The resulting dictionaries.
--- @field players number[] The players who were waiting for this language to complete translation.

return flib_dictionary
