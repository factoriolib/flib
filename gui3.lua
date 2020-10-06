local flib_gui = {}

local guis = {}

-- PRIVATE

local function get_or_create_player_table(player_index)
  local players = global.__flib.gui.players
  local player_table = players[player_index]
  if player_table then
    return player_table
  else
    players[player_index] = {
      guis = {},
      handlers = {}
    }
    return players[player_index]
  end
end

-- create an instance of the GUI
local function create_gui(self, parent, name)
  local gui_name = name and name or self.name
  local player_index = parent.player_index or parent.player.index
  local player_table = get_or_create_player_table(player_index)
  local player_guis = player_table.guis

  if player_guis[gui_name] then
    error(
      "GUI name ["..gui_name.."] is already taken for player ["..player_index.."]. If multiple of the same root are "
      .."needed, provide a unique name for each root as the second argument to `create()`."
    )
  end

  local initial_state = self.init(player_index, gui_name)

  if type(initial_state) ~= "table" then
    error("State must be a table.")
  end

  local gui_data = {
    name = gui_name,
    parent = parent,
    player_index = player_index,
    root_child_index = #parent.children + 1,
    root_name = self.name,
    state = initial_state
  }

  -- TODO
  -- -- since this is the first creation, call `build()` directly and pass the entire GUI table
  -- gui_data.root, gui_data.handlers, gui_data.refs = build(
  --   parent,
  --   self.view(gui_data.state),
  --   gui_data.root_child_index,
  --   {},
  --   {}
  -- )

  player_guis[gui_name] = gui_data
end

-- PUBLIC

function flib_gui.init()
  if global.__flib then
    global.__flib.gui = {players = {}}
  else
    global.__flib = {
      gui = {players = {}}
    }
  end
end

-- register a new GUI
function flib_gui.register(name)
  if guis[name] then
    error("Duplicate GUI name ["..name.."] - every GUI must have a unique name.")
  end

  local obj = {
    create = create_gui,
    name = name
  }
  guis[name] =  obj
  return obj
end

--[[
  -- passing the root obj directly won't work since that won't persist across save/load
  gui.create(player_index, name, root_obj)
  gui.destroy(player_index, name, root_obj)
  -- instead, we just assign each root a unique name...
  gui.create(player_index, root_name, gui_name)
  gui.destroy(player_index, root_name, gui_name)
  -- we could also use object format to avoid passing two names
  root_obj:create(player_index, name)
  root_obj:destroy(player_index, name)
  -- we must also provide a way to destroy GUIs whose roots no longer exist
  -- easier alternative: enforce complete GUI destruction and recreation in on_configuration_changed
  gui.migrate()
]]

return flib_gui