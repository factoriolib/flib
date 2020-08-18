--- Data-stage functions for working with entities.
-- @module entity
-- @alias flib_entity
local flib_entity = {}

-- TODO remove all pcalls

--- Data-stage functions
-- @section

--@ category_name
--@ entity_name
function flib_entity.get(category_name, entity_name)
	local no_err, entity = pcall(function() return data.raw[category_name][entity_name] end)
	if no_err and entity ~= nil and next(entity) ~= nil then
		return entity
	end
	return nil
end

--@ category_name
--@ entity_name
function flib_entity.exists(category_name, entity_name)
	local entity = flib_entity.get(category_name, entity_name)
	return entity and type(entity) == "table"
end

-- -- -- SETTING(WRITE) FUNCTIONS

--@ category_name
--@ entity_name
--@ to_remove_mask_name
function flib_entity.remove_collision_mask(category_name, entity_name, to_remove_mask_name)
	local entity = flib_entity.get(category_name, entity_name)
	if entity then
		local no_err, collision_mask = pcall(function() return entity.collision_mask end)
		if no_err and collision_mask ~= nil then
			for i, mask_name in pairs(collision_mask) do
				if mask_name == to_remove_mask_name then
					table.remove(collision_mask, i)
					return true
				end
			end
		end
	end
	return false
end

--@ category_name
--@ entity_name
--@ to_add_mask_name
function flib_entity.add_collision_mask(category_name, entity_name, to_add_mask_name)
	local entity = flib_entity.get(category_name, entity_name)
	if entity then
		local no_err, collision_mask = pcall(function() return entity.collision_mask end)
		if no_err and collision_mask ~= nil then
			table.insert(collision_mask, to_add_mask_name)
		else
			data.raw[category_name][entity_name].collision_mask = {"item-layer", "object-layer", "player-layer", "water-tile", to_add_mask_name}
		end
		return true
	end
	return false
end

--@ category_name
--@ entity_name
--@ to_add_crafting_category
function flib_entity.add_crafting_category(category_name, entity_name, to_add_crafting_category)
	local entity = flib_entity.get(category_name, entity_name)
	if entity and (entity.type == "assembling-machine" or entity.type == "furnace" or entity.type == "rocket-silo") and data.raw["recipe-category"][to_add_crafting_category] then
		if entity.crafting_categories then
			table.insert(entity.crafting_categories, to_add_crafting_category)
		else
			entity.crafting_categories = { to_add_crafting_category }
		end
		return true
	end
	return false
end

--@ category_name
--@ entity_name
--@ to_remove_crafting_category
function flib_entity.remove_crafting_category(category_name, entity_name, to_remove_crafting_category)
	local entity = flib_entity.get(category_name, entity_name)
	if entity and (entity.type == "assembling-machine" or entity.type == "furnace" or entity.type == "rocket-silo") and entity.crafting_categories then
		for i, crafting_category in pairs(entity.crafting_categories) do
			if crafting_category == to_remove_crafting_category then
				table.remove(entity.crafting_categories, i)
				return true
			end
		end
	end
	return false
end

function flib_entity.get_lab_inputs(lab_name)
	if data.raw["lab"][lab_name] then
		if data.raw["lab"][lab_name].inputs == nil then
			data.raw["lab"][lab_name].inputs = {}
		end

		return data.raw["lab"][lab_name].inputs
	end
	return nil
end

function flib_entity.add_lab_input(lab_name, input_name)
	local inputs = flib_entity.get_lab_inputs(lab_name)
	if inputs then
		local found = false
		for _, input in pairs(inputs) do
			if input_name == input then
				found = true
				break
			end
		end
		if not found then
			table.insert(inputs, input_name)
			return true
		end
	end
	return false
end

function flib_entity.remove_lab_input(lab_name, input_name)
	local inputs = flib_entity.get_lab_inputs(lab_name)
	if inputs then
		local found = false
		for i, input in pairs(inputs) do
			if input_name == input then
				found = i
				break
			end
		end
		if found then
			table.remove(inputs, found)
			return true
		end
	end
	return false
end

function flib_entity.remove_fuel_category(category_name, entity_name, fuel_category)
	local entity = flib_entity.get(category_name, entity_name)

	if entity and type(entity) == "table" then
		if entity.energy_source and entity.energy_source.type == "burner" then
			if entity.energy_source.fuel_category and entity.energy_source.fuel_category == fuel_category then
				entity.energy_source.fuel_category = nil
			else
				for i, f_c in pairs(entity.energy_source.fuel_categories) do
					if f_c == fuel_category then
						table.remove(entity.energy_source.fuel_categories, i)
						break
					end
				end
			end
		end
	end
end

function flib_entity.add_fuel_category(category_name, entity_name, fuel_category)
	local entity = flib_entity.get(category_name, entity_name)

	if entity and type(entity) == "table" then
		if entity.energy_source and entity.energy_source.type == "burner" then
			if entity.energy_source.fuel_category then
				local fuel_categories = {entity.energy_source.fuel_category, fuel_category}
				entity.energy_source.fuel_category = nil
				entity.energy_source.fuel_categories = fuel_categories
			else
				table.insert(entity.energy_source.fuel_categories, fuel_category)
			end
		end
	end
end

function flib_entity.override_mining_result(category_name, entity_name, mining_result)
	local entity = flib_entity.get(category_name, entity_name)

	if entity and type(entity) == "table" then
		entity.minable = mining_result
	end
end