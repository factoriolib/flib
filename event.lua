--- Syntax sugar for event manipulation.
-- Along with the list of functions below, this module dynamically generates syntax-shortcuts for all @{defines.events}
-- events. These shortcuts are only to be used when registering a handler to a single event. To register a handler to
-- multiple events, use @{event.register}.
--
-- To use a shortcut, replace `event.register(defines.events.on_built_entity, handler, filters)` with
-- `event.on_built_entity(handler, filters)`. You can also deregister the handler using `event.on_built_entity(nil)`.
-- @module event
-- @alias flib_event
-- @usage local event = require("__flib__.event")
local flib_event = {}

-- generate syntax shortcuts
for name, id in pairs(defines.events) do
  flib_event[name] = function(handler, filters)
    return script.on_event(id, handler, filters)
  end
end

--- Register or deregister a handler to be run during mod init.
-- @tparam function handler The handler to register, or `nil` to deregister the registered handler.
-- @usage
-- -- register a handler to run during mod init
-- event.on_init(function() log("on_init") end)
-- -- deregister the registered handler, if one exists
-- event.on_init(nil)
function flib_event.on_init(handler)
  return script.on_init(handler)
end

--- Register or deregister a handler to be run during mod load.
-- @tparam function handler The handler to register, or `nil` to deregister the registered handler.
-- @usage
-- -- register a handler to run during mod load
-- event.on_load(function() log("on_load") end)
-- -- deregister the registered handler, if one exists
-- event.on_load(nil)
function flib_event.on_load(handler)
  return script.on_load(handler)
end

--- Register or deregister a handler to be run when mod configuration changes.
-- @tparam function handler The handler to register, or `nil` to deregister the registered handler.
-- @usage
-- -- register a handler to run when mod configuration changes
-- event.on_configuration_changed(function() log("on_configuration_changed") end)
-- -- deregister the registered handler, if one exists
-- event.on_configuration_changed(nil)
function flib_event.on_configuration_changed(handler)
  return script.on_configuration_changed(handler)
end

--- Register or deregister a handler to run every N ticks.
-- @tparam uint nth_tick
-- @tparam function handler The handler to register, or `nil` to deregister the registered handler.
-- @usage
-- -- register a handler to run every 30 ticks
-- event.on_nth_tick(30, function(e) log("30th tick!") end)
-- -- deregister the registered handler, if one exists
-- event.on_nth_tick(30, nil)
function flib_event.on_nth_tick(nth_tick, handler)
  return script.on_nth_tick(nth_tick, handler)
end

-- TODO Nexela link EventFilters to https://lua-api.factorio.com/latest/Event-Filters.html

--- Register or deregister a handler to or from an event or group of events.
-- @tparam EventId|EventId[] ids
-- @tparam function handler The handler to register, or `nil` to deregister the registered handler.
-- @tparam[opt] EventFilters filters
-- @usage
-- -- register a handler to a defines.events event that supports filters
-- event.register(defines.events.on_built_entity, function(e) log("ghost built!") end, {{filter="ghost"}})
-- -- register a handler to a custom-input
-- event.register("my-input", function(e) log("my-input pressed!") end)
-- -- register a handler to multiple events of different types
-- event.register({"my-input", defines.events.on_lua_shortcut}, function(e) log("do something!") end)
-- -- deregister a handler from a single event, if one is registered
-- event.register("my-input", nil)
-- -- deregister a handler from multiple events, if one is registered
-- event.register({"my-input", defines.events.on_lua_shortcut}, nil)
function flib_event.register(ids, handler, filters)
  if type(ids) ~= "table" then
    ids = {ids}
  end
  for i=1,#ids do
    -- dumb workaround - the game doesn't like you passing filters, even if it's nil
    if filters then
      script.on_event(ids[i], handler, filters)
    else
      script.on_event(ids[i], handler)
    end
  end
  return
end

--- Generate a new, unique event ID.
-- @treturn uint
-- @usage
-- -- generate a new event ID
-- local my_event = event.generate_id()
-- -- raise that event with custom parameters
-- event.raise(my_event, {whatever_you_want=true, ...})
function flib_event.generate_id()
  return script.generate_event_name()
end

--- Retrieve the handler for an event, if one exists.
-- @tparam EventId id
-- @treturn function The registered handler, or `nil` if one isn't registered.
-- @usage
-- local existing_handler = event.get_handler(defines.events.on_gui_click)
function flib_event.get_handler(id)
  return script.get_event_handler(id)
end

-- TODO Nexela link EventData to https://lua-api.factorio.com/latest/events.html

--- Raise an event as if it were actually called.
-- @tparam EventId id
-- @tparam EventData event_data The event data that will be passed to the handlers.
-- @usage
-- event.raise(defines.events.on_gui_click, {player_index=e.player_index, element=my_button, ...})
function flib_event.raise(id, event_data)
  return script.raise_event(id, event_data)
end

--- Retrieve the mod event order.
-- @treturn string
-- @usage
-- local event_order = event.get_order()
function flib_event.get_order()
  return script.get_event_order()
end

--- Set the filters for the given event(s).
-- @tparam EventId|EventId[] ids
-- @tparam EventFilters filters The filters to set, or `nil` to clear the filters.
-- @usage
-- -- set the filters for a single event
-- event.set_filters(defines.events.on_built_entity, {
--   {filter="ghost"},
--   {filter="type", type="assembling-machine"}
-- })
-- -- set the filters for multiple events that have compatible formats
-- event.set_filters({defines.events.on_built_entity, defines.events.on_robot_built_entity}, {
--   {filter="ghost"},
--   {filter="type", type="assembling-machine"}
-- })
-- -- clear event filters if any are set
-- event.set_filters(defines.events.on_robot_built_entity, nil)
function flib_event.set_filters(ids, filters)
  if type(ids) ~= "table" then
    ids = {ids}
  end
  for i=1,#ids do
    script.set_event_filter(ids[i], filters)
  end
  return
end

--- Retrieve the filters for the given event.
-- @tparam EventId id
-- @treturn EventFilters filters The filters, or `nil` if there are none defined.
-- @usage
-- local filters = event.get_filters(defines.events.on_built_entity)
function flib_event.get_filters(id)
  return script.get_event_filter(id)
end

--- @Concept EventId
-- One of the following:
-- <ul>
--   <li>A member of @{defines.events}.</li>
--   <li>A positive @{uint} corresponding to a custom event ID.</li>
--   <li>For @{event.register} only - a @{string} corresponding to a custom-input name.</li>
-- </ul>

return flib_event