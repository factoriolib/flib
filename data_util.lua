--- Misc functions for data stage prototype manipulation.
-- @module data_util
-- @usage local data_util = require('__flib__.data_util')
local flib_data_util = {}

--- Copy a prototype, assign new name and minable properties.
-- @tparam PrototypeBase prototype
-- @tparam string new_name string
-- @tparam[opt=false] boolean remove_icon
-- @treturn PrototypeBase
function flib_data_util.copy_prototype(prototype, new_name, remove_icon)
  if not prototype.type or not prototype.name then
    error("Invalid prototype: prototypes must have name and type properties.")
    return nil
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
    for _,result in pairs(p.results) do
      if result.name == prototype.name then
        result.name = new_name
      end
    end
  end
  if remove_icon then
    p.icon = nil
    p.icon_size = nil
    p.icon_mipmaps = nil
    p.icons = nil
  end

  return p
end

--- Add new icon layers to a prototype icon or icons.
-- @tparam PrototypeBase prototype
-- @tparam Types.IconSpecification[] new_layers
-- @return Types.IconSpecification[]|nil
function flib_data_util.create_icons(prototype, new_layers)
  for _,new_layer in pairs(new_layers) do
    if not new_layer.icon or not new_layer.icon_size then
      return nil
    end
  end

  if prototype.icons then
    local icons ={}
    for k,v in pairs(prototype.icons) do
      -- assume every other mod is lacking full prototype definitions
      icons[#icons+1] = {
        icon = v.icon,
        icon_size = v.icon_size or prototype.icon_size or 32,
        tint = v.tint
      }
    end
    for _, new_layer in pairs(new_layers) do
      icons[#icons+1] = new_layer
    end
    return icons

  elseif prototype.icon then
    local icons =
    {
      {
        icon = prototype.icon,
        icon_size = prototype.icon_size,
        icon_mipmaps = prototype.icon_mipmaps,
        tint = {r=1, g=1, b=1, a=1}
      },
    }
    for _, new_layer in pairs(new_layers) do
      icons[#icons+1] = new_layer
    end
    return icons

  else
    return nil
  end
end

local exponent_multipliers = {
  ['n'] = 0.000000001,
  ['u'] = 0.000001,
  ['m'] = 0.001,
  ['k'] = 1000,
  ['M'] = 1000000,
  ['G'] = 1000000000,
  ['T'] = 1000000000000,
  ['P'] = 1000000000000000,
}

--- Convert an energy string to base unit value + suffix.
-- @tparam string energy_string
-- @treturn float|nil
-- @treturn string
function flib_data_util.get_energy_value(energy_string)
  if type(energy_string) == "string" then
    local value, _, exp, unit = string.match(energy_string, "([%-+]?[0-9]*%.?[0-9]+)(([kMGTP]?)([WJ]))")
    if exp and exponent_multipliers[exp] then
      value = value * exponent_multipliers[exp]
    end
    return value, unit
  end
end

return flib_data_util
