--[[
  TRANSLATION MODULE USAGE EXAMPLE

  This example demonstrates the use of the translation module like the other examples do, but it also shows the
  recommended implementation of the module as well. This code accounts for all known edge cases with a player's
  online status and multiplayer sessions. It is recommended that you follow this pattern when implementing the module.
]]

local event = require("__flib__.event")
local migration = require("__flib__.migration")
local translation = require("__flib__.translation")
local table = require("__flib__.table")

-- the structure of a player's translations table
-- this is likely more dictionaries than a mod will actually need - there are a lot of them to facilitate the example
-- strive to translate as few strings as possible to save space in `global`
local empty_translation_tables = {
  achievement = {},
  entity = {},
  equipment = {},
  fluid = {},
  item = {},
  recipe = {},
  technology = {},
  tile = {}
}

-- build the array of strings to translate
local function build_strings()
  local strings = {}
  local i = 0
  -- for demo purposes, we add a LOT of strings by looping through a large amount of game prototypes
  for category in pairs(empty_translation_tables) do
    for name, prototype in pairs(game[category.."_prototypes"]) do
      i = i + 1
      -- StringData - a table containing `dictionary`, `internal`, and `localised` keys
      -- `dictionary` - the dictionary (subtable) that the string belongs to
      -- `internal` - a string that the translation will be keyed by, e.g. "iron-plate"
      -- `localised` - the actual localised string that needs to be translated
      strings[i] = {dictionary=category, internal=name, localised=prototype.localised_name}
    end
  end
  -- save to global
  global.strings = strings
end

-- conditionally registered `on_tick` handler
local function on_tick_handler(e)
  -- if any players are translating, call the function, else deregister from on_tick to save performance
  if translation.translating_players_count() > 0 then
    -- iterate_batch - performs translation operations over multiple ticks
    translation.iterate_batch(e)
  else
    event.on_tick(nil)
  end
end

-- register the `on_tick` handler if it needs to be registered
local function register_on_tick()
  -- if any players are translating, register the handler
  if translation.translating_players_count() > 0 then
    event.on_tick(on_tick_handler)
  end
end

-- create player data
local function init_player(player_index)
  global.players[player_index] = {
    flags = {
      -- if true, start translations for the player when they join
      -- players must be online in order for translations to be processed
      translate_on_join = false
    },
    -- holds the player's translations for use throughout the mod
    translations = table.shallow_copy(empty_translation_tables)
  }
end

local function start_translations(player_index)
  -- add_requests - adds the StringData array to the player's table and starts translation
  translation.add_requests(player_index, global.strings)
  -- register the `on_tick` handler
  register_on_tick()
end

event.on_init(function()
  -- set up the module
  translation.init()

  -- build the array of StringData that the players will translate
  build_strings()

  -- create player data
  global.players = {}
  for i in pairs(game.players) do
    init_player(i)
  end
end)

-- re-register the `on_tick` handler if it needs to be registered
event.on_load(function()
  register_on_tick()
end)

event.on_configuration_changed(function(e)
  -- if generic migrations are necessary
  if migration.on_config_changed(e, {}) then
    -- cancel all translations and do a complete reset
    -- this is necessary because the contents of each dictionary may have changed due to game or mod changes
    translation.init()

    -- re-build the array of StringData that the players will translate
    build_strings()

    -- iterate players
    for i, player in pairs(game.players) do
      -- the player is guaranteed to not be translating anymore, since we did a complete module reset

      local player_table = global.players[e.player_index]

      -- reset the translate_on_join flag
      player_table.flags.translate_on_join = false
      -- reset the player's translations table
      player_table.translations = table.shallow_copy(empty_translation_tables)

      -- the player must be online in order for translations to be processed
      -- if they're online, start immediately, else set a flag to begin when they join
      if player.online then
        start_translations(i)
      else
        global.players[i].flags.translate_on_join = true
      end
    end
  end
end)

event.on_string_translated(function(e)
  -- process_result - retrieves the sort data for the string, and whether or not the player is finished translating
  local sort_data, finished = translation.process_result(e)

  -- `sort_data` can be `nil` if another mod requested translations as well, so check for it
  if sort_data then
    local player_table = global.players[e.player_index]
    local translations = player_table.translations
    -- iterate the ResultSortData
    for dictionary_name, internal_names in pairs(sort_data) do
      -- insert into the corresponding dictionary in the player's table
      local dictionary = translations[dictionary_name]
      -- for each internal name
      for i = 1, #internal_names do
        local internal_name = internal_names[i]
        -- if the translation did not succeed, fall back on the internal name
        -- another valid option is to not add anything if it failed, in which case this logic would be different
        local result = e.translated and e.result or internal_name
        -- add the translation or internal name to the dictionary, keyed by the internal name
        dictionary[internal_name] = result
      end
    end
  end

  -- run some logic when the player is finished translating
  -- this is where you would build your GUI if it depends on the translations existing
  if finished then
    game.print("Player ["..game.get_player(e.player_index).name.."] has finished translations")
  end
end)

event.on_player_created(function(e)
  init_player(e.player_index)
  -- the player is already connected when this event runs, so it's safe to start translations immediately
  start_translations(e.player_index)
end)

event.on_player_joined_game(function(e)
  local player_flags = global.players[e.player_index].flags
  -- if the translate_on_join flag is set
  if player_flags.translate_on_join then
    -- unset the flag so this only happens once
    player_flags.translate_on_join = false
    -- start translating
    start_translations(e.player_index)
  end
end)

event.on_player_left_game(function(e)
  -- if the player is currently translating
  if translation.is_translating(e.player_index) then
    -- cancel the translations
    translation.cancel_requests(e.player_index)
    -- reset the player's translation tables
    local player_table = global.players[e.player_index]
    player_table.translations = table.shallow_copy(empty_translation_tables)
    -- re-set the flag so the translations will restart when they re-join
    player_table.flags.translate_on_join = true
  end
end)

event.on_player_removed(function(e)
  -- if the player is currently translating
  if translation.is_translating(e.player_index) then
    -- cancel the translations
    translation.cancel_requests(e.player_index)
  end
  -- destroy the player's data
  global.players[e.player_index] = nil
end)