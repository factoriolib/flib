if ... ~= "__flib__.train" then
  return require("__flib__.train")
end

--- Functions for working with trains.
--- ```lua
--- local flib_train = require("__flib__.train")
--- ```
--- @class flib_train
local flib_train = {}

local table = table

--- Get the main locomotive in a given train.
--- @param train LuaTrain
--- @return LuaEntity? locomotive The primary locomotive entity or `nil` when no locomotive was found
function flib_train.get_main_locomotive(train)
  if
    train.valid
    and train.locomotives
    and (#train.locomotives.front_movers > 0 or #train.locomotives.back_movers > 0)
  then
    return train.locomotives.front_movers and train.locomotives.front_movers[1] or train.locomotives.back_movers[1]
  end
end

--- Get the backer_name of the main locomotive in a given train.
--- @param train LuaTrain
--- @return string? backer_name The backer_name of the primary locomotive or `nil` when no locomotive was found
function flib_train.get_backer_name(train)
  local loco = flib_train.get_main_locomotive(train)
  return loco and loco.backer_name
end

--- Rotate a single carriage of a train.
--- @param entity LuaEntity
--- @return boolean rotated `true` when rotation was successful.
function flib_train.rotate_carriage(entity)
  local disconnected_back = entity.disconnect_rolling_stock(defines.rail_direction.back)
  local disconnected_front = entity.disconnect_rolling_stock(defines.rail_direction.front)
  entity.rotate({})
  -- Only reconnect the side that was disconnected
  local reconnected_front = disconnected_front
  local reconnected_back = disconnected_back
  if disconnected_back then
    reconnected_back = entity.connect_rolling_stock(defines.rail_direction.front)
  end
  if disconnected_front then
    reconnected_front = entity.connect_rolling_stock(defines.rail_direction.back)
  end

  if disconnected_front and not reconnected_front then
    return false
  end
  if disconnected_back and not reconnected_back then
    return false
  end
  return true
end

--- Create a string representing train composition, and return a count of locomotives and wagons in the train.
--- - `<L<`, `>L>`: Locomotives
--- - `C`: Cargo wagon
--- - `F`: Fluid wagon
--- - `A`: Artillery wagon
--- @param train LuaTrain
--- @return string? composition The composition string, or `nil` if the train was invalid.
--- @return TrainCompositionCounts?
function flib_train.get_composition_string(train)
  if train and train.valid then
    local carriages = train.carriages
    local string_table = {}
    local count_wagons, count_loco_front, count_loco_back, i = 0, 0, 0, 0
    local locos_front = train.locomotives.front_movers
    for _, carriage in pairs(carriages) do
      i = i + 1
      if carriage.type == "locomotive" then
        local faces_forward = false
        for _, loco in pairs(locos_front) do
          if carriage.unit_number == loco.unit_number then
            faces_forward = true
            break
          end
        end
        if faces_forward then
          string_table[i] = "<L<"
          count_loco_front = count_loco_front + 1
        else
          string_table[i] = ">L>"
          count_loco_back = count_loco_back + 1
        end
      elseif carriage.type == "cargo-wagon" then
        count_wagons = count_wagons + 1
        string_table[i] = "C"
      elseif carriage.type == "fluid-wagon" then
        count_wagons = count_wagons + 1
        string_table[i] = "F"
      elseif carriage.type == "artillery-wagon" then
        count_wagons = count_wagons + 1
        string_table[i] = "A"
      else
        count_wagons = count_wagons + 1
        string_table[i] = "?"
      end
    end
    return table.concat(string_table),
      {
        total = i,
        wagons = count_wagons,
        front_movers = count_loco_front,
        back_movers = count_loco_back,
      }
  end
end

--- Open train GUI for one player.
--- @param player_index number
--- @param train LuaTrain
--- @return boolean `true` if the GUI was opened.
function flib_train.open_gui(player_index, train)
  if train and train.valid and game.players[player_index] then
    local loco = flib_train.get_main_locomotive(train)
    if loco and loco.valid then
      game.players[player_index].opened = loco
      return true
    end
  end
  return false
end

return flib_train

--- @class TrainCompositionCounts
--- @field total number The total number of rolling stocks in the train.
--- @field wagons number The number of wagons in the train.
--- @field front_movers number The number of front-facing locomotives in the train.
--- @field back_movers number The number of back-facing locomotives in the train.
