-- ---------------------------------------------------------------------------------------------------------------------
-- DICTIONARY MODULE EXAMPLE CODE
-- This example demonstrates proper use of the module to handle all edge-cases. This example creates dictionaries for
-- the names and descriptions of every entity, fluid, item, recipe, technology, and tile in the game.
-- If an object's name doesn't have a translation, this example enabled a setting that will cause that object to use
-- its InternalString as its TranslatedString. See the `dictionary.new()` documentation for further information.
-- ---------------------------------------------------------------------------------------------------------------------

local event = require("__flib__.event")
local dictionary = require("__flib__.dictionary")
local migration = require("__flib__.migration")

local function create_demo_dictionaries()
  for _, type in pairs{"entity", "fluid", "item", "recipe", "technology", "tile"} do
    -- If the object's name doesn't have a translation, use its internal name as the translation
    local Names = dictionary.new(type.."_names", true)
    -- If a description doesn't exist, it won't exist in the resulting dictionary either
    local Descriptions = dictionary.new(type.."_descriptions")
    for name, prototype in pairs(game[type.."_prototypes"]) do
      Names:add(name, prototype.localised_name)
      Descriptions:add(name, prototype.localised_description)
    end
  end
end

event.on_init(function()
  -- Initialize the module
  dictionary.init()

  global.player_dictionaries = {}
  create_demo_dictionaries()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, {}) then
    -- Reset the module to effectively cancel all ongoing translations and wipe all dictionaries
    dictionary.init()
    create_demo_dictionaries()
  end
end)

event.on_player_created(function(e)
  local player = game.get_player(e.player_index)
  -- Only translate if they're connected - if they're not, then it will not work!
  if player.connected then
    dictionary.translate(player)
  end
end)

event.on_player_joined_game(function(e)
  -- This serves two purposes: To translate the player's initial dictionaries, and to update the language if they player
  -- switched locales.
  dictionary.translate(game.get_player(e.player_index))
end)

event.on_player_left_game(function(e)
  -- If the player was actively translating, cancel it and hand it off to another player (if any).
  dictionary.cancel_translation(e.player_index)
end)

event.on_tick(dictionary.check_skipped)

event.on_string_translated(dictionary.process_translation)

event.register(dictionary.on_language_translated, function(e)
  -- For convenience, store the dictionaries that each player is using in their personal table.
  -- This does not actually take any storage space, because the dictionaries are already stored in the module's internal
  -- table, so any additional references are just pointers to the original.
  for _, player_index in pairs(e.players) do
    global.player_dictionaries[player_index] = e.dictionaries
    game.print("Player "..player_index.." now has dictionaries for their language!")
  end
end)
