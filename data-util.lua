if ... ~= "__flib__.data-util" then
  return require("__flib__.data-util")
end

--- Utilities for data stage prototype manipulation.
--- ```lua
--- local flib_data_util = require("__flib__.data-util")
--- ```
--- @class flib_data_util
local flib_data_util = {}

--- Copy a prototype, assigning a new name and minable properties.
--- @param prototype table
--- @param new_name string string
--- @param remove_icon? boolean
--- @return table
function flib_data_util.copy_prototype(prototype, new_name, remove_icon)
  if not prototype.type or not prototype.name then
    error("Invalid prototype: prototypes must have name and type properties.")
    return --- @diagnostic disable-line
  end
  local p = table.deepcopy(prototype)
  p.name = new_name
  if p.minable and p.minable.result then
    p.minable.result = new_name
  end
  if p.place_result then
    p.place_result = new_name
  end
  if p.result then
    p.result = new_name
  end
  if p.results then
    for _, result in pairs(p.results) do
      if result.name == prototype.name then
        result.name = new_name
      end
    end
  end
  if remove_icon then
    p.icon = nil
    p.icon_size = nil
    p.icons = nil
  end

  return p
end

--- Copy prototype.icon/icons to a new fully defined icons array, optionally adding new icon layers.
---
--- Returns `nil` if the prototype's icons are incorrectly or incompletely defined.
--- @param prototype table
--- @param new_layers? IconSpecification[]
--- @return IconSpecification[]|nil
function flib_data_util.create_icons(prototype, new_layers)
  if new_layers then
    for _, new_layer in pairs(new_layers) do
      if not new_layer.icon or not new_layer.icon_size then
        return nil
      end
    end
  end

  if prototype.icons then
    local icons = {}
    for _, v in pairs(prototype.icons) do
      -- Over define as much as possible to minimize weirdness: https://forums.factorio.com/viewtopic.php?f=25&t=81980
      icons[#icons + 1] = {
        icon = v.icon,
        icon_size = v.icon_size or prototype.icon_size,
        tint = v.tint,
        scale = v.scale,
        shift = v.shift,
      }
    end
    if new_layers then
      for _, new_layer in pairs(new_layers) do
        icons[#icons + 1] = new_layer
      end
    end
    return icons
  elseif prototype.icon then
    local icons = {
      {
        icon = prototype.icon,
        icon_size = prototype.icon_size,
        tint = { r = 1, g = 1, b = 1, a = 1 },
      },
    }
    if new_layers then
      for _, new_layer in pairs(new_layers) do
        icons[#icons + 1] = new_layer
      end
    end
    return icons
  else
    return nil
  end
end

local exponent_multipliers = {
  ["q"] = 0.000000000000000000000000000001,
  ["r"] = 0.000000000000000000000000001,
  ["y"] = 0.000000000000000000000001,
  ["z"] = 0.000000000000000000001,
  ["a"] = 0.000000000000000001,
  ["f"] = 0.000000000000001,
  ["p"] = 0.000000000001,
  ["n"] = 0.000000001,
  ["u"] = 0.000001, -- μ is invalid
  ["m"] = 0.001,
  ["c"] = 0.01,
  ["d"] = 0.1,
  [""] = 1,
  ["da"] = 10,
  ["h"] = 100,
  ["k"] = 1000,
  ["M"] = 1000000,
  ["G"] = 1000000000,
  ["T"] = 1000000000000,
  ["P"] = 1000000000000000,
  ["E"] = 1000000000000000000,
  ["Z"] = 1000000000000000000000,
  ["Y"] = 1000000000000000000000000,
  ["R"] = 1000000000000000000000000000,
  ["Q"] = 1000000000000000000000000000000,
}

--- Convert an energy string to base unit value + suffix.
---
--- Returns `nil` if `energy_string` is incorrectly formatted.
--- @param energy_string string
--- @return number?
--- @return string?
function flib_data_util.get_energy_value(energy_string)
  if type(energy_string) == "string" then
    local v, _, exp, unit = string.match(energy_string, "([%-+]?[0-9]*%.?[0-9]+)((%D*)([WJ]))")
    local value = tonumber(v)
    if value and exp and exponent_multipliers[exp] then
      value = value * exponent_multipliers[exp]
      return value, unit
    end
  end
  return nil
end

--- Build a sprite from constituent parts.
--- @param name? string
--- @param position? MapPosition
--- @param filename? string
--- @param size? Vector
--- @param mods? table
--- @return SpriteSpecification
function flib_data_util.build_sprite(name, position, filename, size, mods)
  local def = {
    type = "sprite",
    name = name,
    filename = filename,
    position = position,
    size = size,
    flags = { "icon" },
  }
  if mods then
    for k, v in pairs(mods) do
      def[k] = v
    end
  end
  return def
end

--- An empty image. This image is 8x8 to facilitate usage with GUI styles.
flib_data_util.empty_image = "__flib__/graphics/empty.png"

--- A black image, for use with tool backgrounds. This image is 1x1.
flib_data_util.black_image = "__flib__/graphics/black.png"

--- A desaturated planner image. Tint this sprite to easily add your own planners.
flib_data_util.planner_base_image = "__flib__/graphics/planner.png"

--- A dark red button tileset. Used for the `flib_tool_button_dark_red` style.
flib_data_util.dark_red_button_tileset = "__flib__/graphics/dark-red-button.png"

--- Returns a list of all prototypes with the given `base_type`.
--- @overload fun(base_type: "achievement"): data.AchievementPrototype[]
--- @overload fun(base_type: "active-trigger"): data.ActiveTriggerPrototype[]
--- @overload fun(base_type: "airborne-pollutant"): data.AirbornePollutantPrototype[]
--- @overload fun(base_type: "ambient-sound"): data.AmbientSound[]
--- @overload fun(base_type: "ammo-category"): data.AmmoCategory[]
--- @overload fun(base_type: "animation"): data.AnimationPrototype[]
--- @overload fun(base_type: "asteroid-chunk"): data.AsteroidChunkPrototype[]
--- @overload fun(base_type: "autoplace-control"): data.AutoplaceSpecification[]
--- @overload fun(base_type: "burner-usage"): data.BurnerUsagePrototype[]
--- @overload fun(base_type: "collision-layer"): data.CollisionLayerPrototype[]
--- @overload fun(base_type: "custom-event"): data.CustomEventPrototype[]
--- @overload fun(base_type: "custom-input"): data.CustomInputPrototype[]
--- @overload fun(base_type: "damage-type"): data.DamageType[]
--- @overload fun(base_type: "decorative"): data.DecorativePrototype[]
--- @overload fun(base_type: "deliver-category"): data.DeliverCategory[]
--- @overload fun(base_type: "deliver-impact-combination"): data.DeliverImpactCombination[]
--- @overload fun(base_type: "editor-controller"): data.EditorControllerPrototype[]
--- @overload fun(base_type: "entity"): data.EntityPrototype[]
--- @overload fun(base_type: "equipment"): data.EquipmentPrototype[]
--- @overload fun(base_type: "equipment-category"): data.EquipmentCategory[]
--- @overload fun(base_type: "equipment-grid"): data.EquipmentGridPrototype[]
--- @overload fun(base_type: "fluid"): data.FluidPrototype[]
--- @overload fun(base_type: "font"): data.FontPrototype[]
--- @overload fun(base_type: "fuel-category"): data.FuelCategory[]
--- @overload fun(base_type: "god-controller"): data.GodControllerPrototype[]
--- @overload fun(base_type: "gui-style"): data.GuiStyle[]
--- @overload fun(base_type: "impact-category"): data.ImpactCategory[]
--- @overload fun(base_type: "item"): data.ItemPrototype[]
--- @overload fun(base_type: "item-group"): data.ItemGroup[]
--- @overload fun(base_type: "item-subgroup"): data.ItemSubGroup[]
--- @overload fun(base_type: "map-gen-presets"): data.MapGenPresets[]
--- @overload fun(base_type: "map-settings"): data.MapSettings[]
--- @overload fun(base_type: "module-category"): data.ModuleCategory[]
--- @overload fun(base_type: "mouse-cursor"): data.MouseCursor[]
--- @overload fun(base_type: "noise-expression"): data.NamedNoiseExpression[]
--- @overload fun(base_type: "noise-function"): data.NamedNoiseFunction[]
--- @overload fun(base_type: "particle"): data.ParticlePrototype[]
--- @overload fun(base_type: "procession"): data.ProcessionPrototype[]
--- @overload fun(base_type: "procession-layer-inheritance-group"): data.ProcessionLayerInheritanceGroup[]
--- @overload fun(base_type: "quality"): data.QualityPrototype[]
--- @overload fun(base_type: "recipe"): data.RecipePrototype[]
--- @overload fun(base_type: "recipe-category"): data.RecipeCategory[]
--- @overload fun(base_type: "remote-controller"): data.RemoteControllerPrototype[]
--- @overload fun(base_type: "resource-category"): data.ResourceCategory[]
--- @overload fun(base_type: "shortcut"): data.ShortcutPrototype[]
--- @overload fun(base_type: "sound"): data.SoundPrototype[]
--- @overload fun(base_type: "space-connection"): data.SpaceConnectionPrototype[]
--- @overload fun(base_type: "space-location"): data.SpaceLocationPrototype[]
--- @overload fun(base_type: "spectator-controller"): data.SpectatorControllerPrototype[]
--- @overload fun(base_type: "sprite"): data.SpritePrototype[]
--- @overload fun(base_type: "surface"): data.SurfacePrototype[]
--- @overload fun(base_type: "surface-property"): data.SurfacePropertyPrototype[]
--- @overload fun(base_type: "technology"): data.TechnologyPrototype[]
--- @overload fun(base_type: "tile"): data.TilePrototype[]
--- @overload fun(base_type: "tile-effect"): data.TileEffectDefinition[]
--- @overload fun(base_type: "tips-and-tricks-item"): data.TipsAndTricksItem[]
--- @overload fun(base_type: "tips-and-tricks-item-category"): data.TipsAndTricksItemCategory[]
--- @overload fun(base_type: "trigger-target-type"): data.TriggerTargetType[]
--- @overload fun(base_type: "trivial-smoke"): data.TrivialSmokePrototype[]
--- @overload fun(base_type: "tutorial"): data.TutorialDefinition[]
--- @overload fun(base_type: "utility-constants"): data.UtilityConstants[]
--- @overload fun(base_type: "utility-sounds"): data.UtilitySounds[]
--- @overload fun(base_type: "utility-sprites"): data.UtilitySounds[]
--- @overload fun(base_type: "virtual-signal"): data.VirtualSignalPrototype[]
function flib_data_util.all(base_type)
  if not base_type then
    error("flib_data_util.all() root was nil")
  end
  if type(base_type) ~= "string" then
    error("flib_data_util.all() root was not a string")
  end
  if not defines.prototypes[base_type] then
    error("flib_data_util.all(): '" .. base_type .. "' is not a valid base prototype type")
  end

  local result = {}
  for prototype_type in pairs(defines.prototypes[base_type]) do
    for _, prototype in pairs(data.raw[prototype_type] or {}) do
      result[#result + 1] = prototype
    end
  end
  return result
end

--- Returns the prototype with the given `base_type` and `name`, if it exists.
--- @overload fun(base_type: "achievement", name: string?): data.AchievementPrototype?
--- @overload fun(base_type: "active-trigger", name: string?): data.ActiveTriggerPrototype?
--- @overload fun(base_type: "airborne-pollutant", name: string?): data.AirbornePollutantPrototype?
--- @overload fun(base_type: "ambient-sound", name: string?): data.AmbientSound?
--- @overload fun(base_type: "ammo-category", name: string?): data.AmmoCategory?
--- @overload fun(base_type: "animation", name: string?): data.AnimationPrototype?
--- @overload fun(base_type: "asteroid-chunk", name: string?): data.AsteroidChunkPrototype?
--- @overload fun(base_type: "autoplace-control", name: string?): data.AutoplaceSpecification?
--- @overload fun(base_type: "burner-usage", name: string?): data.BurnerUsagePrototype?
--- @overload fun(base_type: "collision-layer", name: string?): data.CollisionLayerPrototype?
--- @overload fun(base_type: "custom-event", name: string?): data.CustomEventPrototype?
--- @overload fun(base_type: "custom-input", name: string?): data.CustomInputPrototype?
--- @overload fun(base_type: "damage-type", name: string?): data.DamageType?
--- @overload fun(base_type: "decorative", name: string?): data.DecorativePrototype?
--- @overload fun(base_type: "deliver-category", name: string?): data.DeliverCategory?
--- @overload fun(base_type: "deliver-impact-combination", name: string?): data.DeliverImpactCombination?
--- @overload fun(base_type: "editor-controller", name: string?): data.EditorControllerPrototype?
--- @overload fun(base_type: "entity", name: string?): data.EntityPrototype?
--- @overload fun(base_type: "equipment", name: string?): data.EquipmentPrototype?
--- @overload fun(base_type: "equipment-category", name: string?): data.EquipmentCategory?
--- @overload fun(base_type: "equipment-grid", name: string?): data.EquipmentGridPrototype?
--- @overload fun(base_type: "fluid", name: string?): data.FluidPrototype?
--- @overload fun(base_type: "font", name: string?): data.FontPrototype?
--- @overload fun(base_type: "fuel-category", name: string?): data.FuelCategory?
--- @overload fun(base_type: "god-controller", name: string?): data.GodControllerPrototype?
--- @overload fun(base_type: "gui-style", name: string?): data.GuiStyle?
--- @overload fun(base_type: "impact-category", name: string?): data.ImpactCategory?
--- @overload fun(base_type: "item", name: string?): data.ItemPrototype?
--- @overload fun(base_type: "item-group", name: string?): data.ItemGroup?
--- @overload fun(base_type: "item-subgroup", name: string?): data.ItemSubGroup?
--- @overload fun(base_type: "map-gen-presets", name: string?): data.MapGenPresets?
--- @overload fun(base_type: "map-settings", name: string?): data.MapSettings?
--- @overload fun(base_type: "module-category", name: string?): data.ModuleCategory?
--- @overload fun(base_type: "mouse-cursor", name: string?): data.MouseCursor?
--- @overload fun(base_type: "noise-expression", name: string?): data.NamedNoiseExpression?
--- @overload fun(base_type: "noise-function", name: string?): data.NamedNoiseFunction?
--- @overload fun(base_type: "particle", name: string?): data.ParticlePrototype?
--- @overload fun(base_type: "procession", name: string?): data.ProcessionPrototype?
--- @overload fun(base_type: "procession-layer-inheritance-group", name: string?): data.ProcessionLayerInheritanceGroup?
--- @overload fun(base_type: "quality", name: string?): data.QualityPrototype?
--- @overload fun(base_type: "recipe", name: string?): data.RecipePrototype?
--- @overload fun(base_type: "recipe-category", name: string?): data.RecipeCategory?
--- @overload fun(base_type: "remote-controller", name: string?): data.RemoteControllerPrototype?
--- @overload fun(base_type: "resource-category", name: string?): data.ResourceCategory?
--- @overload fun(base_type: "shortcut", name: string?): data.ShortcutPrototype?
--- @overload fun(base_type: "sound", name: string?): data.SoundPrototype?
--- @overload fun(base_type: "space-connection", name: string?): data.SpaceConnectionPrototype?
--- @overload fun(base_type: "space-location", name: string?): data.SpaceLocationPrototype?
--- @overload fun(base_type: "spectator-controller", name: string?): data.SpectatorControllerPrototype?
--- @overload fun(base_type: "sprite", name: string?): data.SpritePrototype?
--- @overload fun(base_type: "surface", name: string?): data.SurfacePrototype?
--- @overload fun(base_type: "surface-property", name: string?): data.SurfacePropertyPrototype?
--- @overload fun(base_type: "technology", name: string?): data.TechnologyPrototype?
--- @overload fun(base_type: "tile", name: string?): data.TilePrototype?
--- @overload fun(base_type: "tile-effect", name: string?): data.TileEffectDefinition?
--- @overload fun(base_type: "tips-and-tricks-item", name: string?): data.TipsAndTricksItem?
--- @overload fun(base_type: "tips-and-tricks-item-category", name: string?): data.TipsAndTricksItemCategory?
--- @overload fun(base_type: "trigger-target-type", name: string?): data.TriggerTargetType?
--- @overload fun(base_type: "trivial-smoke", name: string?): data.TrivialSmokePrototype?
--- @overload fun(base_type: "tutorial", name: string?): data.TutorialDefinition?
--- @overload fun(base_type: "utility-constants", name: string?): data.UtilityConstants?
--- @overload fun(base_type: "utility-sounds", name: string?): data.UtilitySounds?
--- @overload fun(base_type: "utility-sprites", name: string?): data.UtilitySounds?
--- @overload fun(base_type: "virtual-signal", name: string?): data.VirtualSignalPrototype?
function flib_data_util.get(base_type, name)
  if not base_type then
    error("flib_data_util.get() base_type was nil")
  end
  if type(base_type) ~= "string" then
    error("flib_data_util.get() base_type was not a string")
  end
  if not defines.prototypes[base_type] then
    error("flib_data_util.get(): '" .. base_type .. "' is not a valid base prototype type")
  end

  if not name then
    error("flib_data_util.get() name was nil")
  end
  if type(name) ~= "string" then
    error("flib_data_util.get() name was not a string")
  end

  for derived_type in pairs(defines.prototypes[base_type]) do
    local prototypes = data.raw[derived_type]
    if prototypes then
      local prototype = data.raw[derived_type][name]
      if prototype then
        return prototype
      end
    end
  end
end

return flib_data_util

--- @class IconSpecification
--- @field icon string
--- @field icon_size int
--- @class SpriteSpecification
