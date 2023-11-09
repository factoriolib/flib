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
  else
    return force.get_saved_technology_progress(technology) or 0
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

--- @enum TechnologyResearchState
flib_technology.research_state = {
  available = 1,
  conditionally_available = 2,
  not_available = 3,
  researched = 4,
  disabled = 5,
}

return flib_technology
