--- A GUI library inspired by Elm and Seed-RS.
-- @module gui
-- @alias flib_gui
local flib_gui = {}

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

-- GUI "INSTANCE" FUNCTIONS

-- update the state, generate a new view, diff it, and apply the results
local function update_instance(self, msg, e)
  self.update(self.state, msg, e)

  local new_view = self.view(self.state)

  -- TODO
  -- the stored `last_view` will be modified and consumed to become the diff, in order to avoid deepcopying
  -- local last_view = self.last_view
  -- diff(last_view, new_view)
  -- update_structure(self.root, last_view)

  -- save the new view as the last view for future diffing
  self.last_view = new_view
end

-- destroy the instance and clean up handlers
local function destroy_instance(self)
  local player_table = get_or_create_player_table(self.player_index)
  local player_guis = player_table.guis

  -- TODO
  -- self.root.destroy()
  -- TODO remove handlers from handlers table

  player_guis[self.gui_index] = nil
end

-- GUI "OBJECT" FUNCTIONS

-- create an instance of the GUI
local function create_instance(self, parent, ...)
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
    state = initial_state,
  }

  setmetatable(gui_data, {__index = gui_mts[self.name]})

  player_guis[index] = gui_data
  player_guis.__nextindex = index + 1

  -- TODO actually create the GUI...
  -- build(gui_data, self.view(gui_data.state))

  return gui_data
end

-- PUBLIC FUNCTIONS

--- Initial setup.
--
-- Must be called during `on_init` **before** any GUIs are built.
function flib_gui.init()
  if global.__flib then
    global.__flib.gui = {players = {}}
  else
    global.__flib = {
      gui = {players = {}}
    }
  end
end

--- Restore metatables on all GUI instances.
--
-- Must be called during `on_load`.
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

--- Create a new GUI object.
--
-- This sets up the instance metatable for this GUI and adds the `create()` function to the object.
-- @tparam string name The name of the GUI. Must be unique.
-- @treturn table The newly created GUI object. Add your `init()`, `update()` and `view()` functions to this object
-- before returning it.
-- @usage
-- local my_gui = gui.new("my_gui")
function flib_gui.new(name)
  if gui_mts[name] then
    error("Duplicate GUI name ["..name.."] - every GUI must have a unique name.")
  end

  -- metatable object - what instances of this GUI will use as their `__index`
  gui_mts[name] = {
    destroy = destroy_instance,
    update = update_instance
  }

  return {
    create = create_instance,
    name = name
  }
end

return flib_gui