--- Syntax sugar for event manipulation.
---
--- Along with the documented functions, this module dynamically generates syntax-shortcuts for all `defines.events`
--- events. These shortcuts are only to be used when registering a handler to a single event. To register a handler to
--- multiple events, use `event.register`.
---
--- To use a shortcut, replace `event.register(defines.events.on_built_entity, handler, filters)` with
--- `event.on_built_entity(handler, filters)`. You can also deregister the handler using `event.on_built_entity(nil)`.
local flib_event = {}

-- Generate syntax shortcuts
-- TODO: Find a way to document these
for name, id in pairs(defines.events) do
  flib_event[name] = function(handler, filters)
    return script.on_event(id, handler, filters)
  end
end

--- Register or deregister a handler to be run during mod init.
---
--- # Examples
---
--- ```lua
--- -- Register a handler to run during mod init
--- event.on_init(function() log("on_init") end)
--- -- Deregister the registered handler, if one exists
--- event.on_init(nil)
--- ```
--- @param handler? function The handler to register, or `nil` to deregister the registered handler.
function flib_event.on_init(handler)
  script.on_init(handler)
end

--- Register or deregister a handler to be run during mod load.
---
--- # Examples
---
--- ```lua
--- -- Register a handler to run during mod load
--- event.on_load(function() log("on_load") end)
--- -- Deregister the registered handler, if one exists
--- event.on_load(nil)
--- ```
--- @param handler? function The handler to register, or `nil` to deregister the registered handler.
function flib_event.on_load(handler)
  script.on_load(handler)
end

--- Register or deregister a handler to be run when mod configuration changes.
---
--- # Examples
---
--- ```lua
--- -- Register a handler to run when mod configuration changes
--- event.on_configuration_changed(function() log("on_configuration_changed") end)
--- -- Deregister the registered handler, if one exists
--- event.on_configuration_changed(nil)
--- ```
--- @param handler? function The handler to register, or `nil` to deregister the registered handler.
function flib_event.on_configuration_changed(handler)
  script.on_configuration_changed(handler)
end

--- Register or deregister a handler to run every N ticks.
---
--- # Examples
---
--- ```lua
--- -- Register a handler to run every 30 ticks
--- event.on_nth_tick(30, function(e) log("30th tick!") end)
--- -- Deregister the registered handler, if one exists
--- event.on_nth_tick(30, nil)
--- ```
--- @param nth_tick? uint|uint[] The nth-tick(s) to invoke the handler on, or `nil` to deregister all nth-tick handlers.
--- @param handler? function The handler to register, or `nil` to deregister the registered handler.
function flib_event.on_nth_tick(nth_tick, handler)
  if handler then
    script.on_nth_tick(nth_tick, handler)
  else
    script.on_nth_tick(nth_tick)
  end
end

--- Register or deregister a handler to or from an event or group of events.
---
--- Unlike `script.on_event`, `event.register` supports adding compatible filters to multiple events at once.
--- Additionally, `event.register` supports registering to custom-inputs and other events simultaneously.
---
--- # Examples
---
--- ```lua
--- -- Register a handler to a defines.events event that supports filters
--- event.register(defines.events.on_built_entity, function(e) log("ghost built!") end, {{filter="ghost"}})
--- -- Register a handler to a custom-input
--- event.register("my-input", function(e) log("my-input pressed!") end)
--- -- Register a handler to multiple events of different types
--- event.register({"my-input", defines.events.on_lua_shortcut}, function(e) log("do something!") end)
--- -- Deregister a handler from a single event, if one is registered
--- event.register("my-input", nil)
--- -- Deregister a handler from multiple events, if one is registered
--- event.register({"my-input", defines.events.on_lua_shortcut}, nil)
--- ```
--- @param ids EventId|EventId[]
--- @param handler? function The handler to register, or `nil` to deregister the registered handler.
--- @param filters? EventFilter
function flib_event.register(ids, handler, filters)
  if type(ids) ~= "table" then
    ids = { ids }
  end
  for i = 1, #ids do
    -- the game doesn't like you passing filters to events that don't support them, even if they're `nil`
    if filters then
      script.on_event(ids[i], handler, filters)
    else
      script.on_event(ids[i], handler)
    end
  end
end

--- Register an entity to raise `on_entity_destroyed` when it's destroyed.
---
--- Once an entity is registered it's registered forever (until it's destroyed) and persists through save/load.
---
--- Registered is global across all mods: once an entity is registered the event will be fired for all mods when its
--- destroyed.
---
--- An entity registered multiple times will only fire the event once and gives back the same registration number.
---
--- Depending on when a given entity is destroyed, `on_entity_destroyed` will be fired at the end of the current tick or end
--- of the next tick.
--- @param entity LuaEntity The entity to register.
--- @return number registration_number
function flib_event.register_on_entity_destroyed(entity)
  return script.register_on_entity_destroyed(entity)
end

--- Generate a new, unique event ID.
---
--- # Examples
---
--- ```lua
--- -- Generate a new event ID
--- local my_event = event.generate_id()
--- -- Raise that event with custom parameters
--- event.raise(my_event, {whatever_you_want=true, ...})
--- ```
--- @return uint
function flib_event.generate_id()
  return script.generate_event_name()
end

--- Retrieve the handler for an event, if one exists.
--- @param id uint
--- @return fun(e: EventData)? handler The registered handler, or `nil` if one isn't registered.
function flib_event.get_handler(id)
  return script.get_event_handler(id)
end

--- Raise an event as if it were actually called.
---
--- This will only work for events that actually support being raised, and custom mod events.
---
--- # Examples
---
--- ```lua
--- event.raise(defines.events.on_gui_click, {player_index=e.player_index, element=my_button, ...})
--- ```
--- @param id uint
--- @param event_data table The event data that will be passed to the handlers.
function flib_event.raise(id, event_data)
  script.raise_event(id, event_data)
end

--- Retrieve the mod event order.
--- @return string
function flib_event.get_order()
  return script.get_event_order()
end

--- Set the filters for the given event(s).
---
--- # Examples
---
--- ```lua
--- -- Set the filters for a single event
--- event.set_filters(defines.events.on_built_entity, {
---   {filter="ghost"},
---   {filter="type", type="assembling-machine"}
--- })
--- -- Set the filters for multiple events that have compatible formats
--- event.set_filters({defines.events.on_built_entity, defines.events.on_robot_built_entity}, {
---   {filter="ghost"},
---   {filter="type", type="assembling-machine"}
--- })
--- -- Clear event filters if any are set
--- event.set_filters(defines.events.on_robot_built_entity, nil)
--- ```
--- @param ids uint|uint[]
--- @param filters? EventFilter The filters to set, or `nil` to clear the filters.
function flib_event.set_filters(ids, filters)
  if type(ids) ~= "table" then
    ids = { ids }
  end
  for i = 1, #ids do
    script.set_event_filter(ids[i], filters)
  end
end

--- Retrieve the filters for the given event.
--- @param id uint
--- @return EventFilter? filters The filters, or `nil` if there are none defined.
function flib_event.get_filters(id)
  script.get_event_filter(id)
end

--- One of the following:
--- - A member of `defines.events`
--- - A positive `number` corresponding to a custom event ID.
--- - A `string` corresponding to a custom-input name.
--- @alias EventId defines.events|uint|string

return flib_event
