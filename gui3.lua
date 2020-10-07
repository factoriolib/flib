local flib_gui = {}

local guis = {}
local gui_mts = {}

-- HELPER FUNCTIONS

local function get_or_create_player_table(player_index)
  local players = global.__flib.gui.players
  local player_table = players[player_index]
  if player_table then
    return player_table
  else
    players[player_index] = {
      guis = {
        __nextindex = 1
      },
      handlers = {},
    }
    return players[player_index]
  end
end

-- GUI "OBJECT" FUNCTIONS

-- create an instance of the GUI
local function create_gui(self, parent, ...)
  local player_index = parent.player_index or parent.player.index
  local player_table = get_or_create_player_table(player_index)
  local player_guis = player_table.guis

  local initial_state = self.init(player_index, ...)

  if type(initial_state) ~= "table" then
    error("State must be a table.")
  end

  local index = player_guis.__nextindex

  local gui_data = {
    gui_index = index,
    gui_name = self.name,
    parent = parent,
    player_index = player_index,
    state = initial_state
  }

  setmetatable(gui_data, {__index = gui_mts[self.name]})

  player_guis[index] = gui_data
  player_guis.__nextindex = index + 1

  -- TODO actually create the GUI...

  return gui_data
end

-- GUI "INSTANCE" FUNCTIONS

-- destroy the instance and clean up handlers
local function destroy_gui(self)
  local player_table = get_or_create_player_table(self.player_index)
  local player_guis = player_table.guis

  -- TODO
  -- self.root.destroy()
  -- TODO remove handlers from handlers table

  player_guis[self.gui_index] = nil
end

-- PUBLIC FUNCTIONS

function flib_gui.init()
  if global.__flib then
    global.__flib.gui = {players = {}}
  else
    global.__flib = {
      gui = {players = {}}
    }
  end
end

function flib_gui.load()
  for _, player_table in pairs(global.__flib.gui.players) do
    for key, gui_data in pairs(player_table.guis) do
      if key ~= "__nextindex" then
        local gui_mt = gui_mts[gui_data.gui_name]
        -- if the GUI object no longer exists, then the mod version changed and things will get cleaned up anyway
        if gui_mt then
          setmetatable(gui_data, {__index = gui_mt})
        end
      end
    end
  end
end

function flib_gui.register(name)
  if guis[name] then
    error("Duplicate GUI name ["..name.."] - every GUI must have a unique name.")
  end

  -- metatable object - what instances of this GUI will use as their `__index`
  gui_mts[name] = {
    destroy = destroy_gui
  }

  local obj = {
    create = create_gui,
    name = name
  }
  guis[name] =  obj
  return obj
end

return flib_gui