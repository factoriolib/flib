--- @module control.event
-- Syntax sugar for event manipulation.
-- @usage local event = require("__flib__.control.event")
local event = {}

local bootstrap_events = {"on_init", "on_load", "on_configuration_changed"}

-- TODO: Raiguard - Write docs

for _, name in ipairs(bootstrap_events) do
  event[name] = function(handler)
    return script[name](handler)
  end
end

for name, id in pairs(defines.events) do
  event[name] = function(handler, filters)
    return script.on_event(id, handler, filters)
  end
end

function event.on_nth_tick(nth_tick, handler)
  return script.on_nth_tick(nth_tick, handler)
end

function event.register(ids, handler, filters)
  if type(ids) ~= "table" then
    ids = {ids}
  end
  for i=1,#ids do
    script.on_event(ids[i], handler, filters)
  end
  return
end

function event.generate_id()
  return script.generate_event_name()
end

function event.get_handler(id)
  return script.get_event_handler(id)
end

function event.raise(id, event_data)
  return script.raise_event(id, event_data)
end

function event.get_order()
  return script.get_event_order()
end

function event.set_filters(ids, filters)
  if type(ids) ~= "table" then
    ids = {ids}
  end
  for i=1,#ids do
    script.set_event_filter(ids[i], filters)
  end
  return
end

function event.get_filters(id)
  return script.get_event_filter(id)
end

return event