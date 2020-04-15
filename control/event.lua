---@module control.event
---@usage local event = require("__flib__.control.event")
local event = {}

local math_min = math.min
local table_insert = table.insert
local table_remove = table.remove

-- holds registered events for dispatch
local events = {}
-- holds conditional event data
local conditional_events = {}
-- conditional events by group
local conditional_event_groups = {}

-- bootstrap events do not go through dispatch_event, and have extra functionality
local bootstrap_events = {on_init=true, on_init_postprocess=true, on_load=true, on_load_postprocess=true, on_configuration_changed=true}

-- calls handler functions tied to an event
-- all non-bootstrap events go through this function
local function dispatch_event(e)
  local global_data = global.__flib.event
  local con_registry = global_data.conditional_events
  local player_lookup = global_data.players

  -- retrieve event registry
  local registry
  if e.nth_tick then
    registry = events[-e.nth_tick]
  elseif e.input_name then
    registry = events[e.input_name]
  else
    registry = events[e.name]
  end
  -- error checking
  if not registry then
    error("Event is registered but has no handlers!")
  end

  -- for every handler registered to this event
  for _,t in ipairs(registry) do
    local handler = t.handler
    local options = t.options
    local conditional_names = t.conditional_names

    -- check if any userdata has gone invalid since last iteration
    if not options.skip_validation then
      for _,v in pairs(e) do
        if type(v) == "table" and v.__self and not v.valid then
          return
        end
      end
    end

    -- check conditional requirements, or call the handler for static events
    if conditional_names then
      for name,_ in pairs(conditional_names) do
        local con_data = con_registry[name]
        if not con_data then error("Conditional event ["..name.."] has been raised, but has no data!") end
        -- add conditional event name to the event table
        e.conditional_name = name

        -- if con_data is true, just call the handler
        if con_data == true then
          e.registered_players = nil
          handler(e)
        else
          local players = con_data.players
          -- add registered players to the event table
          e.registered_players = players

          -- if there is a player index, check if that specific player is registered
          if e.player_index then
            local player_events = player_lookup[e.player_index]
            if player_events and player_events[name] then
              handler(e)
            end
          -- otherwise, just call the handler
          else
            handler(e)
          end
        end
      end
    else
      handler(e)
    end
  end
  return
end

-- BOOTSTRAP EVENTS
-- these events are handled specially and do not go through dispatch_event

script.on_init(function()
  global.__flib = {
    event = {conditional_events={}, players={}}
  }
  -- dispatch events
  for _,t in ipairs(events.on_init or {}) do
    t.handler()
  end
  -- dispatch postprocess events
  for _,t in ipairs(events.on_init_postprocess or {}) do
    t.handler()
  end
end)

script.on_load(function()
  -- dispatch events
  for _,t in ipairs(events.on_load or {}) do
    t.handler()
  end
  -- dispatch postprocess events
  for _,t in ipairs(events.on_load_postprocess or {}) do
    t.handler()
  end
  -- re-register conditional events
  local con_registry = global.__flib.event.conditional_events
  for name,_ in pairs(con_registry) do
    local data = conditional_events[name]
    if data then
      event.register(data.id, data.handler, data.options, name)
    else
      log("Conditional event ["..name.."] was enabled on save, but now has no registration data and was not re-enabled. If the name was changed, the event "
        .." must be re-enabled in on_configuration_changed. If it was removed entirely, its global data must be removed in on_configuration_changed.")
    end
  end
end)

script.on_configuration_changed(function(e)
  -- dispatch events
  for _,t in ipairs(events.on_configuration_changed or {}) do
    t.handler(e)
  end
end)

---@section Registration

--- Register a static (non-conditional) handler.
---@param id EventId|EventId[]
---@param handler function
---@param options EventOptions
---@param conditional_name nil
---@usage
-- -- Register a handler to run on every tick
-- event.register(defines.events.on_tick, function(e) game.print(game.tick) end)
-- -- Register a handler for Nth tick using negative numbers
-- event.register(-10, function(e) game.print("Every 10 ticks") end)
-- -- Custom inputs and bootstrap events
-- event.register("mmd-open-gui", handler)
-- event.register("on_configuration_changed", handler)
function event.register(id, handler, options, conditional_name)
  options = options or {}
  if type(id) ~= "table" then id = {id} end

  for _,n in pairs(id) do
    -- create registry and register master handler, if needed
    if not events[n] then
      events[n] = {}
      if not bootstrap_events[n] then
        if type(n) == "number" and n < 0 then
          script.on_nth_tick(-n, dispatch_event)
        else
          script.on_event(n, dispatch_event)
        end
      end
    end
    local registry = events[n]

    -- make sure the handler has not already been registered
    for _,t in ipairs(registry) do
      if t.handler == handler then
        -- add conditional name to the list if there is one
        if conditional_name then
          t.conditional_names[conditional_name] = true
        end
        -- do nothing else
        return
      end
    end

    -- insert handler
    local data = {handler=handler, options=options}
    if conditional_name then
      data.conditional_names = {[conditional_name]=true}
    end
    if options.insert_at then
      table_insert(registry, math_min(#registry+1, options.insert_at), data)
    else
      table_insert(registry, data)
    end
  end
  return
end

--- Register conditional (non-static) handlers.
---@param events ConditionalEvents
---@usage
-- event.register_conditional{
--   place_fire_at_feet = {id=defines.events.on_tick, handler=place_fire},
--   void_chests_tick = {id=defines.events.on_tick, handler=void_chests}
-- }
function event.register_conditional(events)
  for n,t in pairs(events) do
    if conditional_events[n] then
      error("Duplicate conditional event ["..n.."]!")
    end
    t.options = t.options or {}
    -- add to conditional events table
    conditional_events[n] = t
    -- add to group lookup
    local groups = t.group
    if groups then
      if type(groups) ~= "table" then groups = {groups} end
      for i=1,#groups do
        local group = conditional_event_groups[groups[i]]
        if group then
          group[#group+1] = n
        else
          conditional_event_groups[groups[i]] = {n}
        end
      end
    end
  end
end

--- Enable a conditional handler.
---@param name string
---@param[opt] player_index integer
---@usage
-- -- Enable a global conditional handler
-- event.enable("void_chests_tick")
-- -- Enable a conditional handler for a specific player
-- event.enable("place_fire_at_feet", e.player_index)
function event.enable(name, player_index)
  local data = conditional_events[name]
  if not data then
    error("Conditional event ["..name.."] was not registered and has no data!")
  end
  local global_data = global.__flib.event
  local saved_data = global_data.conditional_events[name]
  local add_player_data = false
  if saved_data then
    -- update existing data / add this player
    if player_index then
      if saved_data == true then
        error("Tried to add a player to global conditional event ["..name.."]!")
      end
      local player_lookup = global_data.players[player_index]
      -- check if they're already registered
      if player_lookup and player_lookup[name] then
        -- don't do anything
        if not data.options.suppress_logging then
          log("Tried to re-register conditional event ["..name.."] for player "..player_index..", skipping!")
        end
        return
      else
        add_player_data = true
      end
    else
      if not data.options.suppress_logging then
        log("Conditional event ["..name.."] was already registered, skipping!")
      end
      return
    end
  else
    -- add to global
    if player_index then
      global_data.conditional_events[name] = {players={}}
      add_player_data = true
    else
      global_data.conditional_events[name] = true
    end
    saved_data = global_data.conditional_events[name]
  end

  if add_player_data then
    local player_lookup = global_data.players[player_index]
    table_insert(saved_data.players, player_index)
    -- add to player lookup table
    if not player_lookup then
      global_data.players[player_index] = {[name]=true}
    else
      player_lookup[name] = true
    end
  end
  -- register handler
  event.register(data.id, data.handler, data.options, name)
end

--- Disable a conditional handler.
---@param name string
---@param[opt] player_index integer
---@usage
-- -- Disable a global conditional handler
-- event.disable("void_chests_tick")
-- -- Disable a conditional handler for a specific player
-- event.disable("place_fire_at_feet", e.player_index)
function event.disable(name, player_index)
  local data = conditional_events[name]
  if not data then
    error("Tried to disable conditional event ["..name.."], which does not exist!")
  end
  local global_data = global.__flib.event
  local saved_data = global_data.conditional_events[name]
  if not saved_data then
    if not data.options.suppress_logging then
      log("Tried to disable conditional event ["..name.."], which is not enabled!")
    end
    return
  end
  -- remove player from / manipulate global data
  if player_index then
    -- check if the player is actually registered to this event
    if global_data.players[player_index][name] then
      -- remove from players subtable
      for i,pi in ipairs(saved_data.players) do
        if pi == player_index then
          table_remove(saved_data.players, i)
          break
        end
      end
      -- remove from lookup table
      global_data.players[player_index][name] = nil
      -- remove lookup table if it's empty
      if table_size(global_data.players[player_index]) == 0 then
        global_data.players[player_index] = nil
      end
    else
      if not data.options.suppress_logging then
        log("Tried to disable conditional event ["..name.."] from player "..player_index.." when it wasn't enabled for them!")
      end
      return
    end
    if #saved_data.players == 0 then
      global_data.conditional_events[name] = nil
    else
      -- don't do anything else
      return
    end
  else
    if type(saved_data) == "table" then
      -- remove from all player lookup tables
      local players = global_data.players
      for i=1,#saved_data.players do
        players[saved_data.players[i]][name] = nil
      end
    end
    global_data.conditional_events[name] = nil
  end

  -- deregister handler
  local id = data.id
  if type(id) ~= "table" then id = {id} end
  for _,n in pairs(id) do
    local registry = events[n]
    -- error checking
    if not registry or #registry == 0 then
      log("Tried to deregister an unregistered event of id ["..n.."]")
      return
    end
    for i,t in ipairs(registry) do
      if t.handler == data.handler then
        -- remove conditional name from table
        t.conditional_names[name] = nil
        if table_size(t.conditional_names) > 0 then
          -- don't actually remove or deregister the handler
          return
        end
        -- remove the handler from the events tables
        table_remove(registry, i)
      end
    end
    -- de-register the master handler if it's no longer needed
    if #registry == 0 then
      if type(n) == "number" and n < 0 then
        script.on_nth_tick(-n, nil)
      else
        script.on_event(n, nil)
      end
      events[n] = nil
    end
  end
end

--- Enable a group of conditional handlers.
---@param group string
---@param player_index integer
---@usage
-- -- Enable a group of conditional handlers
-- event.enable_group("group_1")
-- -- Enable a group of conditional handlers for a specific player
-- event.enable_group("player_group", e.player_index)
function event.enable_group(group, player_index)
  local group_events = conditional_event_groups[group]
  if not group_events then error("Group ["..group.."] has no handlers!") end
  for i=1,#group_events do
    event.enable(group_events[i], player_index)
  end
end

--- Disable a group of conditional handlers.
---@param group string
---@param player_index integer
---@usage
-- -- Disable a group of conditional handlers
-- event.disable_group("group_1")
-- -- Disable a group of conditional handlers for a specific player
-- event.disable_group("player_group", e.player_index)
function event.disable_group(group, player_index)
  local group_events = conditional_event_groups[group]
  if not group_events then error("Group ["..group.."] has no handlers!") end
  for i=1,#group_events do
    event.disable(group_events[i], player_index)
  end
end

---@section Shortcut functions

-- TODO: how to document!?

function event.on_nth_tick(nth_tick, handler, options)
  return event.register(-nth_tick, handler, options)
end

for n,_ in pairs(bootstrap_events) do
  event[n] = function(handler)
    event.register(n, handler)
  end
end

for n,id in pairs(defines.events) do
  event[n] = function(handler, options)
    event.register(id, handler, options)
  end
end

---@section Event manipulation

--- Raise an event as if it were actually called.
---@param id EventId|EventId[]
---@param event_data EventData
---@usage
-- -- Raise an event as if it were really called
-- event.raise(defines.events.on_built_entity, {player_index=1, created_entity=my_entity, stack=my_stack})
function event.raise(id, event_data)
  script.raise_event(id, event_data)
  return
end

--- Set or remove the event's filters.
---@param id EventId|EventId[]
---@param filters EventFilters[]
---@usage
-- -- Set the filters for an event
-- event.set_filters(defines.events.on_built_entity, {{filter="ghost_name", name="demo-entity-1"}, {filter="ghost"}})
function event.set_filters(id, filters)
  if type(id) ~= "table" then id = {id} end
  for _,n in pairs(id) do
    script.set_event_filter(n, filters)
  end
  return
end

--- Check if a conditional event is enabled.
---@param name string
---@param player_index integer
---@usage
-- -- Check if a conditional event is enabled
-- if event.is_enabled("print_when_built") then game.print("someone registered this event!") end
-- -- Check if a conditional event is enabled for a specific player
-- if event.is_enabled("player_built_entity", player.index) then game.print(player.name.." registered this event!")
function event.is_enabled(name, player_index)
  local global_data = global.__flib.event
  local registry = global_data.conditional_events[name]
  if registry then
    if player_index then
      for _,i in ipairs(registry.players) do
        if i == player_index then
          return true
        end
      end
      return false
    end
    return true
  end
  return false
end

-- holds custom event IDs
local custom_id_registry = {}

--- Generate or retrieve a custom event ID.
---@param name string
---@usage
-- -- Generate a new event ID, or retrieve it if it has already been made
-- local custom_event = event.generate_id("example")
-- -- Listen for the event
-- event.register(custom_event, handler)
-- -- Raise the custom event
-- event.raise(custom_event, {whatever_you_want=true, ...})
-- -- Alternatively, use the function call directly
-- event.register(event.get_id("example"), handler)
-- event.raise(event.get_id("example"), {whatever_you_want=true, ...})
function event.get_id(name)
  if not custom_id_registry[name] then
    custom_id_registry[name] = script.generate_event_name()
  end
  return custom_id_registry[name]
end

--- Save a custom event ID.
---@param name string
---@param id integer
---@usage
-- Save an event ID retrieved from another mod
-- event.save_id("other_mods_event", remote.call("other_mod", "custom_event"))
function event.save_id(name, id)
  if custom_id_registry[name] then
    log("Overwriting entry in custom event registry: ["..name.."]")
  end
  custom_id_registry[name] = id
end

event.events = events
event.conditional_events = conditional_events
event.conditional_event_groups = conditional_event_groups

return event

---@section Concepts
-- TODO: Fix documentation style if needed

--- One of the following:
-- - A member of [defines.events](https://lua-api.factorio.com/latest/defines.html#defines.events).
-- - A [string](https://lua-api.factorio.com/latest/builtin-types.html#string) corresponding to a `custom-input` prototype name, or a bootstrap event.
-- - A negative [int](https://lua-api.factorio.com/latest/builtin-types.html#int) corresponding to an `nth_tick` value.
-- - A positive [int](https://lua-api.factorio.com/latest/builtin-types.html#int) corresponding to a custom mod-generated event.
-- **Examples**
-- `defines.events.on_player_created`
-- `'rll-open-search'`
-- `' on_init'`
-- `-25`
-- `241`
---@class EventId


--- Table with the following fields:
-- - skip_validation :: [boolean](https://lua-api.factorio.com/latest/Builtin-Types.html#boolean) (optional): If true, validation of userdata will be skipped when the event is raised. This saves on performance, but doesn't protect against crashes relating to invalid userdata!
-- - insert_at :: [int](https://lua-api.factorio.com/latest/Builtin-Types.html#int) (optional): Inserts the handler at the given position in the event table, instead of at the back.
-- **Examples**
-- `{skip_validation=true, insert_at=1}`
---@class EventOptions

--- Dictionary [string](https://lua-api.factorio.com/latest/Builtin-Types.html#string) -> [table](https://lua-api.factorio.com/latest/Builtin-Types.html#table). Each table of this dictionary has the following fields:
-- - id :: [EventId](#eventid) or array of [EventId](#eventid): The event ID(s) to invoke the handler on.
-- - handler :: function(event): The handler to run. Receives an event table [as defined in the Factorio documentation](https://lua-api.factorio.com/latest/events.html).
-- - group :: [string](https://lua-api.factorio.com/latest/Builtin-Types.html#string) or array of [string](https://lua-api.factorio.com/latest/Builtin-Types.html#string) (optional): Assigns this event to one or more groups.
-- - gui_filters :: [GuiFilter](#guifilter) or array of [GuiFilter](#guifilter) (optional): Static GUI filters to use for this event.
-- - options :: [EventOptions](#eventoptions) (optional): Additional options.
---@class ConditionalEvents

---@class EventFilters https://lua-api.factorio.com/latest/Event-Filters.html
---@class EventData https://lua-api.factorio.com/latest/events.html