--[[
  NEW GUI MODULE
  Take inspiration from the Elm architecture and React
  - `init`, `state`, `update`, and `view`
    - `init`: returns the initial state of the state
    - `state`: the GUI's "state" that is mutated and used to determine what is shown
    - `refs`: references to GUI elements in the tree for use in updaters
    - `update`: updates the state based on a message and event data
    - `view`: builds a representation of the GUI and diffs it with the current GUI (if any)
  - a GUI can be arbitrarily split into "components"
    - each component implements all of the above fields
  - state is stored in `__flib` and is retrieved via `component:get_state(identifier)`
  - will require nuking and rebuilding _everything_ on `on_configuration_changed` to avoid problems
]]

local flib_gui = {}

local components = {}

-- UTILITY FUNCTIONS

local function get_component_name(base, identifier)
  if identifier then
    return base.."&&"..identifier
  else
    return base
  end
end

local function diff(parent, view)
  parent.add{type = "label", caption = "DEFD:FLSDHJF:LSDH:LIFHSDILFHL:SDHF"}
end

-- COMPONENT METHODS

-- when directly created, a component will be stored in `global` and have its update() function be callable
local function create_component(self, parent, identifier)
  local component_name = get_component_name(self.name, identifier)


  local component_registry = global.__flib.gui.components

  -- check registry for this component
  if component_registry[component_name] then
    error(
      "Attempted to create duplicate component ["..component_name.."]. If multiple copies of a component are needed, a "
      .."unique identifier must be given to each one as a third argument."
    )
  end

  local player_index = parent.player_index

  local initial_state = self.init(player_index, identifier)

  if type(initial_state) ~= "table" then
    error("State must be a table.")
  end

  local component_tbl = {
    state = initial_state
  }

  component_tbl.parent = diff(parent, self.view(component_tbl.state))

  component_registry[component_name] = component_tbl
end

-- retrieves and returns a component's state table
local function get_component_state(self, identifier)
  local component_name = get_component_name(self.name, identifier)
  local component_data = global.__flib.gui.components[component_name]

  if component_data then
    return component_data
  else
    error("Only 'root' components (those created with `:create()`) store retrievable state.")
  end
end

local component_mt = {
  __call = function(self, ...)
    local view = self.view(...)
    view.__componentname = self.name
    return view
  end,
  -- __newindex = function(self, k, v)
  --   if k == "update" then
  --     rawset(self, "update", function(self, ...)
  --       self.update_internal(...)
  --     end)
  --     rawset(self, "update_internal", v)
  --   else
  --     rawset(self, k, v)
  --   end
  -- end
}

-- PUBLIC FUNCTIONS

function flib_gui.component(name)
  if components[name] then
    error("Duplicate component name ["..name.."] - every component must have a unique name.")
  end

  local component = {
    create = create_component,
    get_state = get_component_state,
    name = name
  }
  setmetatable(component, component_mt)

  components[name] = component

  return component
end

function flib_gui.init()
  local base = {
    components = {},
    handlers = {}
  }
  if global.__flib then
    global.__flib.gui = base
  else
    global.__flib = {gui = base}
  end
end

return flib_gui