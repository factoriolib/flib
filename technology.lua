if ... ~= "__flib__.technology" then
  return require("__flib__.technology")
end

--- @class flib_technology
local flib_technology = {}

--- Gets the active or saved research progress for the given technology.
--- @param technology LuaTechnology
--- @param level uint
--- @return double
function flib_technology.get_research_progress(technology, level)
  local force = technology.force
  local current_research = force.current_research
  if current_research and current_research.name == technology.name then
    if technology.level == level or not flib_technology.is_multilevel(technology) then
      return force.research_progress
    else
      return 0
    end
  elseif technology.level == level then
    return force.get_saved_technology_progress(technology) or 0
  else
    return 0
  end
end

--- Gets the research unit count for the given technology.
--- @param technology LuaTechnology
--- @param level uint?
--- @return uint
function flib_technology.get_research_unit_count(technology, level)
  local formula = technology.research_unit_count_formula
  if formula then
    local level = level or technology.level
    return math.floor(game.evaluate_expression(formula, { l = level, L = level }))
  end
  return math.floor(technology.research_unit_count)
end

--- Returns whether the technology has multiple levels.
--- @param technology LuaTechnology|LuaTechnologyPrototype
--- @return boolean
function flib_technology.is_multilevel(technology)
  if technology.object_name == "LuaTechnology" then
    technology = technology.prototype
  end
  return technology.level ~= technology.max_level
end

--- Returns `true` if the first technology should be ordered before the second technology. For use in `table.sort`.
--- @param tech_a LuaTechnologyPrototype
--- @param tech_b LuaTechnologyPrototype
--- @return boolean
function flib_technology.sort_predicate(tech_a, tech_b)
  local ingredients_a = tech_a.research_unit_ingredients
  local ingredients_b = tech_b.research_unit_ingredients
  local len_a = #ingredients_a
  local len_b = #ingredients_b
  -- Always put technologies with zero ingredients at the front
  if (len_a == 0) ~= (len_b == 0) then
    return len_a == 0
  end
  if #ingredients_a > 0 then
    -- Compare ingredient order strings
    -- Check the most expensive packs first, and sort based on the first difference
    for i = 0, math.min(len_a, len_b) - 1 do
      local ingredient_a = ingredients_a[len_a - i]
      local ingredient_b = ingredients_b[len_b - i]
      local order_a = game[ingredient_a.type .. "_prototypes"][ingredient_a.name].order
      local order_b = game[ingredient_b.type .. "_prototypes"][ingredient_b.name].order
      -- Cheaper pack goes in front
      if order_a ~= order_b then
        return order_a < order_b
      end
    end
    -- Sort the technology with fewer ingredients in front
    if len_a ~= len_b then
      return len_a < len_b
    end
  end
  -- Compare technology order strings
  local order_a = tech_a.order
  local order_b = tech_b.order
  if order_a ~= order_b then
    return order_a < order_b
  end
  -- Compare prototype names
  return tech_a.name < tech_b.name
end

--- Returns the technology's prototype name with the level suffix stripped.
--- @param technology LuaTechnology|LuaTechnologyPrototype
--- @return string
function flib_technology.get_base_name(technology)
  local result = string.gsub(technology.name, "%-%d*$", "")
  return result
end

--- If the technology is multi-level, returns the technology's base name with that level appended, otherwise returns the technology name.
--- @param technology LuaTechnology
--- @param level uint
--- @return string
function flib_technology.get_leveled_name(technology, level)
  if flib_technology.is_multilevel(technology) then
    return flib_technology.get_base_name(technology) .. "-" .. level
  else
    return technology.name
  end
end

--- @enum TechnologyResearchState
flib_technology.research_state = {
  available = 1,
  conditionally_available = 2,
  not_available = 3,
  researched = 4,
  disabled = 5,
}

return flib_technology
