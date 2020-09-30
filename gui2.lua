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

GLOBAL STRUCTURE
global.__flib.gui
  players
    [player_index]
      components (change to "roots"?)
      handlers
        [element_index]
          [event_id]
            component_name
            msg

]]

local flib_gui = {}

local components = {}

local event_keys = {}

for key, id in pairs(defines.events) do
  if string.find(key, "gui") then
    event_keys[string.gsub(key, "_gui", "")] = id
  end
end

-- UTILITY FUNCTIONS

-- convert message if it was shortcutted
local function standardize_msg(msg)
  if type(msg) == "string" then
    return {name = msg}
  end
  return msg
end

local function add_or_change_handler(elem_index, event_id, component_data, msg)
  local __gui = global.__flib.gui

  local player_data = __gui.players[component_data.player_index]
  if not player_data then
    __gui.players[component_data.player_index] = {}
    player_data = __gui.players[component_data.player_index]
  end

  local player_handlers = player_data.handlers
  local elem_data = player_handlers[elem_index]

  if not elem_data then
    player_handlers[elem_index] = {}
    elem_data = player_handlers[elem_index]
  end

  local event_data = elem_data[event_id]
  if event_data then
    event_data.msg = msg
  else
    elem_data[event_id] = {
      component_name = component_data.name,
      msg = msg
    }
  end
end

local function remove_handler(elem_index, event_id, player_index)
  local __gui = global.__flib.gui

  local player_data = __gui.players[player_index]
  if not player_data then return end

  local player_handlers = player_data.handlers
  local elem_data = player_handlers[elem_index]
  if not elem_data then return end

  elem_data[event_id] = nil

  if table_size(elem_data) == 0 then
    player_handlers[elem_index] = nil
  end
end

local function get_component_name(base, identifier)
  if identifier then
    return base.."&&"..identifier
  else
    return base
  end
end

local function diff(component_data, parent, view, index, assigned_handlers)
  local children = parent.children
  local elem = children[index]
  if not elem then
    elem = parent.add(view)
  elseif view.type ~= elem.type then
    -- delete this and all elements after this
    -- TODO insert instead, if the capability is ever added to the API :(
    for i = index, #children do
      children[i].destroy()
    end
  end
  local elem_index = elem.index
  for key, value in pairs(view) do
    local event_id = event_keys[key]
    if key ~= "children" then
      if key == "style" then
        if elem.style.name ~= value then
          elem.style = value
        end
      elseif event_id then
        add_or_change_handler(elem_index, event_id, component_data, standardize_msg(value))
        local elem_handlers = assigned_handlers[elem_index]
        if elem_handlers then
          elem_handlers[event_id] = true
        else
          assigned_handlers[elem_index] = {[event_id] = true}
        end
      elseif elem[key] ~= value then
        elem[key] = value
      end
    end
  end
  local children = view.children
  if children then
    local children_len = #children
    local i = 0
    for _ = 1, children_len do
      i = i + 1
      assigned_handlers = diff(component_data, elem, children[i], i, assigned_handlers)
    end
    for i = i + 1, children_len do
      children[i].destroy()
    end
  end
  return assigned_handlers, elem
end

-- COMPONENT METHODS

-- when directly created, a component will be stored in `global` and have its update() function be callable
local function create_component(self, parent, identifier)
  local component_name = get_component_name(self.name, identifier)
  local player_index = parent.player_index

  local module_data = global.__flib.gui

  local player_data = module_data.players[player_index]
  if not player_data then
    module_data.players[player_index] = {
      components = {},
      handlers = {}
    }
    player_data = module_data.players[player_index]
  end

  -- check registry for this component
  if player_data.components[component_name] then
    error(
      "Attempted to create duplicate component ["..component_name.."]. If multiple copies of a component are needed, a "
      .."unique identifier must be given to each one as a third argument."
    )
  end

  local initial_state = self.init(player_index, identifier)

  if type(initial_state) ~= "table" then
    error("State must be a table.")
  end

  local component_data = {
    base_name = self.name,
    identifier = identifier,
    name = component_name,
    parent = parent,
    player_index = player_index,
    root_child_index = #parent.children + 1,
    state = initial_state,
  }

  component_data.assigned_handlers, component_data.root = diff(
    component_data,
    parent,
    self.view(component_data.state),
    #parent.children + 1,
    {}
  )

  player_data.components[component_name] = component_data
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

-- updates state and view for the component
-- only usable on root components
local function update_and_diff_component(self, player_index, msg, identifier, event_data)
  local component_data = (
    global.__flib.gui.players[player_index].components[get_component_name(self.name, identifier)]
  )

  if component_data then
    local state = component_data.state
    self.update(msg, state, identifier, event_data)
    local assigned_handlers = diff(
      component_data,
      component_data.parent,
      self.view(state, identifier),
      component_data.root_child_index,
      component_data.assigned_handlers
    )

    -- remove any handlers that are no longer needed
    for index, new_handlers in pairs(component_data.assigned_handlers) do
      local old_handlers = assigned_handlers[index]
      if old_handlers then
        for event_id in pairs(old_handlers) do
          if not new_handlers[event_id] then
            remove_handler(index, event_id)
          end
        end
      end
    end
  else
    error("`update_and_diff()` is only callable on 'root' components.")
  end
end

local component_mt = {
  __call = function(self, state, identifier)
    local view = self.view(state, identifier)
    -- view.__componentname = get_component_name(self.name, identifier)
    return view
  end
}

-- PUBLIC FUNCTIONS

function flib_gui.component(name)
  if components[name] then
    error("Duplicate component name ["..name.."] - every component must have a unique name.")
  end

  local component = {
    create = create_component,
    get_state = get_component_state,
    name = name,
    update_and_diff = update_and_diff_component
  }
  setmetatable(component, component_mt)

  components[name] = component

  return component
end

function flib_gui.init()
  local base = {
    players = {}
  }
  if global.__flib then
    global.__flib.gui = base
  else
    global.__flib = {gui = base}
  end
end

function flib_gui.dispatch(event_data)
  local element = event_data.element
  local player_index = event_data.player_index
  if not element or not player_index then return false end

  local player_data = global.__flib.gui.players[player_index]
  if not player_data then return false end

  local elem_index = element.index

  local elem_handlers = player_data.handlers[elem_index]
  if not elem_handlers then return false end

  local handler_data = elem_handlers[event_data.name]
  if handler_data then
    local component_name = handler_data.component_name
    local component_data = player_data.components[component_name]
    local component = components[component_data.base_name]
    if not component_data then
      error("GUI handlers may only be called for 'root' components.")
    end
    component:update_and_diff(event_data.player_index, handler_data.msg, component_data.identifier, event_data)
    return true
  else
    return false
  end
end

function flib_gui.register_handlers()
  for name, id in pairs(defines.events) do
    if string.find(name, "gui") then
      script.on_event(id, flib_gui.dispatch)
    end
  end
end

return flib_gui