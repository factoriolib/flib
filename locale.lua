local flib_prototypes = require("__flib__.prototypes")

--- Provides utilities for deducing the localised names of various prototypes in the prototype stage.
--- Inspired by Rusty's Locale Utilities: https://github.com/theRustyKnife/rusty-locale
--- @class flib_locale
local flib_locale = {}

--- Returns the localised name of the given prototype.
--- @overload fun(prototype: data.PrototypeBase): data.LocalisedString
--- @overload fun(base_type: string, name: string): data.LocalisedString
function flib_locale.of(prototype, name)
  -- In this case, `prototype` is actually `base_type`.
  if type(prototype) == "string" then
    return flib_locale.of(flib_prototypes.get(prototype, name) --[[@as data.PrototypeBase]])
  end
  if prototype.type == "recipe" then
    return flib_locale.of_recipe(prototype --[[@as data.RecipePrototype]])
  elseif defines.prototypes.item[prototype.type] then
    return flib_locale.of_item(prototype --[[@as data.ItemPrototype]])
  else
    return prototype.localised_name or { prototype.type .. "-name." .. prototype.name }
  end
end

--- Returns the localised name of the given item.
--- @param item data.ItemPrototype
--- @return data.LocalisedString
function flib_locale.of_item(item)
  if not defines.prototypes.item[item.type] then
    error("Given prototype is not an item: " .. serpent.block(item))
  end
  if item.localised_name then
    return item.localised_name
  end
  local type_name = "item"
  --- @type data.PrototypeBase?
  local prototype
  if item.place_result then
    type_name = "entity"
    prototype = flib_prototypes.get("entity", item.place_result) --[[@as data.PrototypeBase]]
  elseif item.place_as_equipment_result then
    type_name = "equipment"
    prototype = flib_prototypes.get("equipment", item.place_as_equipment_result) --[[@as data.PrototypeBase]]
  elseif item.place_as_tile then
    local tile_prototype = data.raw.tile[item.place_as_tile.result]
    -- Tiles with variations don't have a localised name
    if tile_prototype and tile_prototype.localised_name then
      prototype = tile_prototype
      type_name = "tile"
    end
  end
  return prototype and prototype.localised_name or { type_name .. "-name." .. item.name }
end

--- Returns the localised name of the given recipe.
--- @param recipe data.RecipePrototype
--- @return data.LocalisedString
function flib_locale.of_recipe(recipe)
  if recipe.type ~= "recipe" then
    error("Given prototype is not an recipe: " .. serpent.block(recipe))
  end
  if recipe.localised_name then
    return recipe.localised_name
  end
  local main_product = recipe.main_product -- LuaLS gets confused if we don't assign to a local.
  if main_product == "" then
    return { "recipe-name." .. recipe.name }
  elseif main_product then
    return flib_locale.of_item(flib_prototypes.get("item", main_product))
  end
  local results = recipe.results
  if results and #results == 1 then
    return flib_locale.of_item(flib_prototypes.get("item", results[1].name))
  end
  return { "recipe-name." .. recipe.name }
end

return flib_locale
