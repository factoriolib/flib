local flib_dictionary = require("__flib__/dictionary-lite")

-- Build demo dictionaries for various kinds of prototypes. Dictionaries don't need to be sorted like this, they can
-- contain anything and everything. For example, in many of my mods I will make a "search" dictionary containing all
-- of the things I need to search, prefixed by their type (i.e. `fluid/crude-oil`, `item/iron-plate`, etc).
local function build_dictionaries()
  for type, prototypes in pairs({
    entity = game.entity_prototypes,
    equipment = game.equipment_prototypes,
    equipment_category = game.equipment_category_prototypes,
    fluid = game.fluid_prototypes,
    fuel_category = game.fuel_category_prototypes,
    item = game.item_prototypes,
    item_group = game.item_group_prototypes,
    recipe = game.recipe_prototypes,
    recipe_category = game.recipe_category_prototypes,
    resource_category = game.resource_category_prototypes,
    technology = game.technology_prototypes,
  }) do
    flib_dictionary.new(type)
    for name, prototype in pairs(prototypes) do
      -- Fall back to the internal name if the localised name is invalid. If you don't want to include invalid strings
      -- then simply pass `prototype.localised_name` and the resulting dictionary will only include valid translations.
      flib_dictionary.add(type, name, { "?", prototype.localised_name, name })
    end
  end
end

-- Handle all relevant events automatically. Be sure to add this line before defining any of your own event handlers.
-- `dictionary-lite` has handlers for `on_init`, `on_configuration_changed`, `on_tick`, `on_string_translated`, and `on_player_joined_game`.
flib_dictionary.handle_events()

script.on_init(function()
  -- If you override any handlers for the events listed above, you will need to manually call the requisite functions.
  flib_dictionary.on_init()
  build_dictionaries()
end)

script.on_configuration_changed(function()
  flib_dictionary.on_configuration_changed()
  -- Dictionaries should be built both during `on_init` and `on_configuration_changed`.
  build_dictionaries()
end)

-- `on_player_dictionaries_ready` is raised when a given player's dictionaries are... ready. Shocking!
script.on_event(flib_dictionary.on_player_dictionaries_ready, function(e)
  -- Alternatively, you can get specific dictionaries with `flib_dictionary.get(e.player_index, "item")` et al.
  local dicts = flib_dictionary.get_all(e.player_index)
  if not dicts then
    return
  end
  if __DebugAdapter then
    __DebugAdapter.print(dicts)
  else
    log(serpent.block(dicts))
  end
end)
