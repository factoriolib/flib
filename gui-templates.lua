if ... ~= "__flib__.gui-templates" then
  return require("__flib__.gui-templates")
end

local flib_math = require("__flib__.math")
local flib_gui = require("__flib__.gui-lite")
local flib_table = require("__flib__.table")
local flib_technology = require("__flib__.technology")

local flib_gui_templates = {}

--- Create and return a technology slot. `on_click` must be a registered GUI handler through `gui-lite`.
--- @param parent LuaGuiElement
--- @param technology LuaTechnology
--- @param level uint
--- @param research_state TechnologyResearchState
--- @param on_click GuiElemHandler?
--- @return LuaGuiElement
function flib_gui_templates.technology_slot(parent, technology, level, research_state, on_click)
  local technology_prototype = technology.prototype

  local is_multilevel = flib_technology.is_multilevel(technology)

  local research_state_str = flib_table.find(flib_technology.research_state, research_state)
  local style = "flib_technology_slot_" .. research_state_str
  if technology.upgrade or is_multilevel or technology_prototype.level > 1 then
    style = style .. "_multilevel"
  end

  local base = parent.add({
    type = "sprite-button",
    name = technology.name,
    style = style,
    elem_tooltip = { type = "technology", name = technology.name },
  })
  if on_click then
    base.tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = on_click })
  end
  base
    .add({ type = "flow", style = "flib_technology_slot_sprite_flow", ignored_by_interaction = true })
    .add({ type = "sprite", style = "flib_technology_slot_sprite", sprite = "technology/" .. technology.name })

  if technology.upgrade or is_multilevel or technology_prototype.level > 1 then
    base.add({
      type = "label",
      name = "level_label",
      style = "flib_technology_slot_level_label_" .. research_state_str,
      caption = level,
      ignored_by_interaction = true,
    })
  end
  if is_multilevel then
    local max_level = technology_prototype.max_level
    local max_level_str = max_level == flib_math.max_uint and "[img=infinity]" or tostring(max_level)
    base.add({
      type = "label",
      name = "level_range_label",
      style = "flib_technology_slot_level_range_label_" .. research_state_str,
      caption = technology_prototype.level .. " - " .. max_level_str,
      ignored_by_interaction = true,
    })
  end

  local ingredients_flow = base.add({
    type = "flow",
    style = "flib_technology_slot_ingredients_flow",
    ignored_by_interaction = true,
  })

  local ingredients = technology.research_unit_ingredients
  local ingredients_len = #ingredients
  for i = 1, ingredients_len do
    local ingredient = ingredients[i]
    ingredients_flow.add({
      type = "sprite",
      style = "flib_technology_slot_ingredient",
      sprite = ingredient.type .. "/" .. ingredient.name,
      ignored_by_interaction = true,
    })
  end
  ingredients_flow.style.horizontal_spacing = flib_math.clamp((68 - 16) / (ingredients_len - 1) - 16, -15, -5)

  local progress = flib_technology.get_research_progress(technology, level)

  base.add({
    type = "progressbar",
    name = "progressbar",
    style = "flib_technology_slot_progressbar",
    value = progress,
    visible = progress > 0,
    ignored_by_interaction = true,
  })

  return base
end

return flib_gui_templates
