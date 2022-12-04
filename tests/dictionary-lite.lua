local dictionary = require("__flib__/dictionary-lite")
local migration = require("__flib__/migration")

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
    dictionary.new(type)
    for name, prototype in pairs(prototypes) do
      -- Use the internal name if the localised name isn't valid
      dictionary.add(type, name, { "?", prototype.localised_name, name })
      -- dictionary.add(type, name, prototype.localised_name)
    end
  end
end

dictionary.handle_events()

script.on_init(function()
  dictionary.on_init()
  build_dictionaries()
end)

migration.handle_on_configuration_changed(nil, function()
  dictionary.on_configuration_changed()
  build_dictionaries()
end)

script.on_event(dictionary.on_player_dictionaries_ready, function(e)
  local dicts = dictionary.get_all(e.player_index)
  if not dicts then
    return
  end
  -- TODO: Ensure that all translations are present
  if __DebugAdapter then
    __DebugAdapter.print(dicts)
  else
    log(serpent.block(dicts))
  end
end)
