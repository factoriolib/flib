local event = require("__flib__.event")

-- LuaBootstrap events are usable simply by replacing `script` with `event`
event.on_init(function()
  log("on init!")
end)
event.on_load(function()
  log("on load!")
end)
event.on_configuration_changed(function(e)
  log("on configuration changed!")
end)
event.on_nth_tick(60, function(e)
  log("one second has passed!")
end)

-- syntax shortcuts - when registering to a single `defines.events` event, follow this syntax:
-- `script.on_event(defines.events.on_player_created, handler, filters)` -> `event.on_player_created(handler, filters)`
event.on_player_created(function(e)
  log("player " .. game.get_player(e.player_index).name .. " created!")
end)

-- event.register - register to custom-input events, or multiple events simultaneously
-- mostly equivalent to `script.on_event` for these cases
event.register("my-custom-input", function(e)
  log("custom input pressed!")
end)
event.register({ defines.events.on_player_left_game, defines.events.on_player_removed }, function(e)
  log("player left or was removed")
end)

-- bonus feature: `event.register` can register custom-inputs and `defines.events` events simultaneously
-- trying to do this with `script.on_event` will error
event.register({ "my-other-custom-input", defines.events.on_lua_shortcut }, function(e)
  log("input or shortcut pressed!")
end)

-- bonus feature: you can add event filters to multiple events simultaneously, assuming the filters are compatible with
-- all of the events
-- trying to do this with `script.on_event` will error
event.register({ defines.events.on_built_entity, defines.events.on_robot_built_entity }, function(e)
  log("entity built!")
end, {
  { filter = "type", type = "transport-belt" },
  { filter = "type", type = "underground-belt" },
  { filter = "type", type = "splitter" },
  { filter = "type", type = "loader" },
  { filter = "type", type = "loader-1x1" },
})

-- these functions are simple name changes - they are functionally identical
local registration_number = event.register_on_entity_destroyed(...)
local my_event_id = event.generate_id()
local handler = event.get_handler(defines.events.on_tick)
event.raise(my_event_id, { my_data = "foo" })
local order = event.get_order()
local filters = event.get_filters(defines.events.on_built_entity)

-- `event.set_filters` has the bonus ability to add compatible filters to multiple events simultaneously
event.set_filters({ defines.events.on_built_entity, defines.events.on_robot_built_entity }, {
  { filter = "type", type = "transport-belt" },
  { filter = "type", type = "underground-belt" },
  { filter = "type", type = "splitter" },
  { filter = "type", type = "loader" },
  { filter = "type", type = "loader-1x1" },
})
