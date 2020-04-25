--- Organizes and runs translations for localised strings.
-- After starting a translation using the translation.start() function, the module will translate 50 entries per tick.
-- Once it has completed translation of a dictionary, an event will be raised that will provide the player index and
-- the output tables. Listen for this event to receive and store the results of the translations.
-- @module control.translation
-- @usage
-- local translation = require("__flib__.control.translation")
-- -- Store a dictionary when its translations have finished.\
-- event.register(translation.on_finished, function(e)
--   global.players[e.player_index].dictionary[e.dictionary_name] = {
--     lookup = e.lookup, -- translation -> array of internal names
--     sorted_translations = e.sorted_translations, -- array of translations
--     translations = e.translations -- internal name -> translation
--   }
-- end)
local translation = {}

--- @class OnTickEventData https://lua-api.factorio.com/latest/events.html#on_tick
--- @class OnStringTranslatedEventData https://lua-api.factorio.com/latest/events.html#on_string_translated

-- locals
local math_floor = math.floor
local string_gsub = string.gsub
local string_lower = string.lower
local table_sort = table.sort

local on_finished_handler = function(e) error("Must register a handler using translation.on_finished()") end

-- converts a localised string into a format readable by the API
-- basically just spits out the table in string form
local function serialise_localised_string(t)
  local output = "{"
  if type(t) == "string" then return t end
  for _, v in pairs(t) do
    if type(v) == "table" then
      output = output..serialise_localised_string(v)
    else
      output = output.."\""..v.."\", "
    end
  end
  output = string_gsub(output, ", $", "").."}"
  return output
end

--- Translate a batch of 50 strings.
-- @tparam OnTickEventData e
function translation.translate_batch(e)
  local __translation = global.__flib.translation
  if __translation.active_translations_count == 0 then return end
  local iterations = math_floor(50 / __translation.active_translations_count)
  if iterations < 1 then iterations = 1 end
  -- for each player that is doing a translation
  for pi, pt in ipairs(__translation.players) do
    local request_translation = game.get_player(pi).request_translation
    local next_index = pt.next_index
    local finish_index = next_index + iterations
    local strings = pt.strings
    local strings_len = pt.strings_len
    -- request translations for the next n strings
    for i=next_index, finish_index do
      if i <= strings_len then
        request_translation(strings[i])
      else
        break
      end
    end
    -- update next index
    pt.next_index = finish_index + 1
  end
end

--- Sort a translated string into its appropriate dictionaries.
-- @tparam OnStringTranslatedEventData e
function translation.sort_string(e)
  local __translation = global.__flib.translation
  local player_data = __translation.players[e.player_index]
  local active_translations = player_data.active_translations
  local localised = e.localised_string
  local serialised = serialise_localised_string(localised)
  -- check if the string actually exists in the registry.
  -- if it does not, then another mod requested this translation as well and it was already sorted.
  local string_registry = player_data.string_registry[serialised]
  if string_registry then
    -- for each dictionary that requested this string
    for dictionary_name,  internal_names in pairs(string_registry) do
      local data = active_translations[dictionary_name]
      -- extra sanity check
      if data then
        -- remove from registry index
        data.registry_index[serialised] = nil
        data.registry_index_size = data.registry_index_size - 1

        -- check if the string was successfully translated
        local success = e.translated
        local result = e.result
        local include_failed_translations = data.include_failed_translations
        if not include_failed_translations and (not success or result == "") then
          log("["..dictionary_name.."]["..e.player_index.."]:  key "..serialised.." was not successfully translated, and will not be included in the output.")
        else
          -- do this only if the result will be the same for all internal names
          if success then
            -- add to lookup table
            data.lookup[string_lower(result)] = internal_names
            -- add to sorted results table
            data.sorted_translations[#data.sorted_translations+1] = data.lowercase_sorted_translations and string_lower(result) or result
          end

          -- for every internal name that this string applies do
          for i=1, #internal_names do
            local internal = internal_names[i]
            -- set result to internal name if the translation failed and the option is active
            if not success and include_failed_translations then
              result = internal
              -- add to lookup and sorted_translations tables here, as each iteration will have a different name
              local lookup = data.lookup[result]
              if lookup then
                lookup[#lookup+1] = internal
              else
                data.lookup[result] = {internal}
              end
              data.sorted_translations[#data.sorted_translations+1] = result
            end
            -- add to translations table
            if data.translations[internal] then
              error("Duplicate key ["..internal.."] in dictionary: "..dictionary_name)
            else
              data.translations[internal] = result
            end
          end
        end

        -- check if this dictionary has finished translation
        if data.registry_index_size == 0 then
          -- sort sorted results table
          table_sort(data.sorted_translations)
          -- decrement active translation counters
          __translation.active_translations_count = __translation.active_translations_count - 1
          player_data.active_translations_count = player_data.active_translations_count - 1
          -- raise finished event with the output tables
          on_finished_handler{
            name = "flib_translation_on_finished",
            tick = game.tick,
            player_index = e.player_index,
            dictionary_name = dictionary_name,
            lookup = data.lookup,
            sorted_translations = data.sorted_translations,
            translations = data.translations
          }
          -- remove from active translations table
          player_data.active_translations[dictionary_name] = nil

          -- check if the player is done translating
          if player_data.active_translations_count == 0 then
            -- remove player's translation table
            __translation.players[e.player_index] = nil
          end
        end
      else
        error("Data for dictionary: "..dictionary_name.." for player: "..e.player_index.." does not exist!")
      end
    end

    -- remove from string registry
    player_data.string_registry[serialised] = nil
  end
end

translation.serialise_localised_string = serialise_localised_string

--- Begin translating strings.
-- @tparam uint player_index
-- @tparam string dictionary_name
-- @tparam TranslationData data
-- @tparam[opt] TranslationOptions options
function translation.start(player_index, dictionary_name, data, options)
  options = options or {}
  local __translation = global.__flib.translation
  local player_data = __translation.players[player_index]

  -- create player table if it doesn't exist
  if not player_data then
    __translation.players[player_index] = {
      active_translations = {}, -- contains data for each dictionary that is being translated
      active_translations_count = 0, -- count of translations that this player is performing
      next_index = 1, -- index of the next string to be translated
      string_registry = {}, -- contains data on where a translation should be placed
      strings = {}, -- contains the actual localised string objects to be translated
      strings_len = 0 -- length of the strings table, for use in on_tick to avoid extraneous logic
    }
    player_data = __translation.players[player_index]
  -- reset if the translation is already running
  elseif player_data.active_translations[dictionary_name] then
    log("Cancelling and restarting translation of dictionary ["..dictionary_name.."] for player ["..player_index.."]")
    translation.cancel(player_index, dictionary_name)
  end

  -- create local references
  local string_registry = player_data.string_registry
  local strings = player_data.strings

  local registry_index = {} -- contains a table of keys that represent all the places in the string index that this dictionary has a place in

  -- add data to translation tables
  for i=1, #data do
    local t = data[i]
    local localised = t.localised
    local serialised = serialise_localised_string(localised)
    -- check for this string in the global string registry
    local registry_entry = string_registry[serialised]
    if registry_entry then
      -- check if this dictionary has been added to this registry yet
      if registry_index[serialised] then
        local our_registry = registry_entry[dictionary_name]
        our_registry[#our_registry+1] = t.internal
      else
        registry_index[serialised] = true
        registry_entry[dictionary_name] = {t.internal}
      end
    else
      -- this is a new string, so add it to the strings table and create the registry
      strings[#strings+1] = localised
      string_registry[serialised] = {[dictionary_name]={t.internal}}
      registry_index[serialised] = true
    end
  end

  -- set new strings table length
  player_data.strings_len = #strings

  -- add this dictionary"s data to the player"s table
  player_data.active_translations[dictionary_name] = {
    -- string registry index
    registry_index = registry_index,
    registry_index_size = table_size(registry_index), -- used to determine when the translation has finished
    -- options
    lowercase_sorted_translations = options.lowercase_sorted_translations,
    include_failed_translations = options.include_failed_translations,
    -- output
    lookup = {},
    sorted_translations = {},
    translations = {}
  }

  -- increment active translations counters, register on_tick and sort result handlers
  __translation.active_translations_count = __translation.active_translations_count + 1
  player_data.active_translations_count = player_data.active_translations_count + 1
end

--- Cancel an ongoing translation.
-- @tparam uint player_index
-- @tparam string dictionary_name
function translation.cancel(player_index, dictionary_name)
  local __translation = global.__flib.translation
  local player_data = __translation.players[player_index] or {active_translations={}}
  local translation_data = player_data.active_translations[dictionary_name]
  if not translation_data then
    log("Tried to cancel translation of dictionary ["..dictionary_name.."] for player ["..player_index.."] when it wasn't running!")
    return
  end
  log("Canceling translation of dictionary ["..dictionary_name.."] for player ["..player_index.."]")

  -- remove this dictionary from the string registry
  local string_registry = player_data.string_registry
  for key in pairs(translation_data.registry_index) do
    local key_registry = string_registry[key]
    key_registry[dictionary_name] = nil
    if table_size(key_registry) == 0 then
      string_registry[key] = nil
    end
  end

  -- decrement active translation counters
  __translation.active_translations_count = __translation.active_translations_count - 1
  player_data.active_translations_count = player_data.active_translations_count - 1
  -- remove from active translations table
  player_data.active_translations[dictionary_name] = nil

  -- check if the player is done translating
  if player_data.active_translations_count == 0 then
    -- remove player's translation table
    __translation.players[player_index] = nil
  end
end

--- Cancel all translations for a specific player, or for everybody.
-- @tparam[opt] uint player_index The player whose translations to cancel. If not provided, all translations for every
-- player are canceled.
function translation.cancel_all(player_index)
  local players = global.__flib.translation.players
  if player_index then
    local player_table = players[player_index]
    if player_table then
      for name in pairs(player_table.active_translations) do
        translation.cancel(player_index, name)
      end
    end
  else
    for i, t in pairs(players) do
      for name in pairs(t.active_translations) do
        translation.cancel(i, name)
      end
    end
  end
end

--- Register a handler to be called when a translation finishes.
-- This does not go through the event system and so doesn't have any of those features, but it passes an event table as
-- if it was one.
-- @tparam function handler The handler to run.
function translation.on_finished(handler)
  on_finished_handler = handler
end

-- set up global
function translation.on_init()
  if not global.__flib then
    global.__flib = {
      translation = {
        active_translations_count = 0,
        players = {}
      }
    }
  else
    global.__flib.translation = {
      active_translations_count = 0,
      players = {}  
    }
  end
end

-- cancel all translations for the player when they leave or are removed
function translation.on_player_left(e)
  local player_translation = global.__flib.translation.players[e.player_index]
  if player_translation and player_translation.active_translations_count > 0 then
    translation.cancel_all(e.player_index)
  end
end

--- @Concepts TranslationData
-- Array of tables. Each table has the following fields:
-- @tparam string internal The internal name that will be used to look up the translation.
-- @tparam Concepts.LocalisedString localised The localised string corresponding to the internal name.
-- @usage
-- {
--   {internal="iron-ore", localised={"item-name.iron-ore"}},
--   {internal="parked-at-depot", localised={"ltnm-gui.parked-at-depot"}}
-- }

--- @Concepts TranslationOptions
-- Table with the following fields:
-- @tparam boolean lowercase_sorted_translations If true, the contents of the sorted_translations table will be all
-- lowercase.
-- @tparam boolean include_failed_trainslations If true, failed translations will still be added to the
-- output tables

return translation