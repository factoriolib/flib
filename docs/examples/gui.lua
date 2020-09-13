local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")
local mod_gui = require("__core__.lualib.mod-gui")

-- add structure templates. this can be multiple levels deep, but this example only uses one level
-- in order to be usable, a template must have a `type` or another `template` key
gui.add_templates{
  mouse_filter = {type="button", mouse_button_filter={"left"}},
  -- elem mods - allows changing properties on an element immediately after creation
  -- available modifications are listen in the LuaGuiElement docs
  drag_handle = {type="empty-widget", style="flib_titlebar_drag_handle", elem_mods={ignored_by_interaction=true}},
  -- a template that depends on another template will load that template first, then apply its own properties on top
  frame_action_button = {template="mouse_filter", style="frame_action_button"}
}

-- add handlers to be usable in `gui.build`
gui.add_handlers{
  --[[
    organize the handlers however you like. in this example, the handlers for the inventory window elements are kept in
    their own subtable, while the handler for the location button is separate
  ]]
  inventory = {
    -- a handler group - contains `defines.events` event name -> handler function pairs
    titlebar_button = {
      -- only `on_gui` events can be used in this table
      -- a handler group can have multiple events, but this example only has one
      on_gui_click = function(e)
        game.get_player(e.player_index).print("You clicked one of the titlebar buttons!")
      end
    },
    slot_button = {
      on_gui_click = function(e)
        local _, _, name = string.find(e.element.sprite, "item/(.*)")
        game.get_player(e.player_index).print("You clicked the "..name.." slot button!")
      end
    },
    window = {
      -- any `on_gui` event can be used
      on_gui_location_changed = function(e)
        local location = e.element.location
        global.players[e.player_index].gui.location.caption = location.x..", "..location.y
      end
    }
  },
  location = {
    on_gui_click = function(e)
      global.players[e.player_index].gui.inventory.window.force_auto_center()
    end
  }
}

-- create the GUIs
local function create_guis(player)
  -- location button - kept in the `mod-gui` button flow
  local location_elems = gui.build(mod_gui.get_button_flow(player), {
    {type="button", style=mod_gui.button_style, caption="0, 0", handlers="location", save_as="label"}
  })

  -- inventory GUI - kept in `screen`
  local inventory_elems = gui.build(player.gui.screen, {
    -- handlers - dot-deliminated path to a handler group table in `gui.handlers`
    -- children - an array of GuiStructures to add as children of this element
    {type="frame", direction="vertical", handlers="inventory.window", save_as="window", children={
      -- save_as - dot-deliminated path to save this element to in `inventory_elems`
      {type="flow", save_as="titlebar.flow", children={
        {type="label", style="frame_title", caption="Demo GUI", elem_mods={ignored_by_interaction=true}},
        {template="drag_handle"},
        -- you can assign multiple elements to the same handler group
        {template="frame_action_button", handlers="inventory.titlebar_button"},
        {template="frame_action_button", handlers="inventory.titlebar_button"},
        {template="frame_action_button", handlers="inventory.titlebar_button"}
      }},
      -- style mods - change style properties on an element immediately after creation
      -- available properties are listen in the LuaStyle docs
      {type="frame", style="inside_shallow_frame_with_padding", style_mods={padding=12}, children={
        {type="frame", style="slot_button_deep_frame", children={
          {type="scroll-pane", style="flib_naked_scroll_pane_no_padding", style_mods={height=200}, children={
            {type="table", style="slot_table", style_mods={width=400}, column_count=10, save_as="slot_table"}
          }}
        }}
      }}
    }}
  })

  -- inventory_elems was built using the structure defined in the `save_as` keys
  -- the titlebar flow was saved to the `titlebar` subtable
  inventory_elems.titlebar.flow.drag_target = inventory_elems.window
  inventory_elems.window.force_auto_center()

  -- update_filters - add or remove filters to or from a handler group
  -- string filters are valid to be used as a filter as well
  -- if the name contains two adjacent underscores `__`, they and everything after them will be ignored
  -- this string filter is what will be matched, we will use `__` on element names later on
  gui.update_filters("inventory.slot_button", player.index, {"demo_slot_button"}, "add")

  global.players[player.index].gui = {inventory=inventory_elems, location=location_elems.label}
end

local function destroy_guis(player, player_table)
  -- destroy parents for both GUIs and clean up tables
  player_table.gui.inventory.window.destroy()
  player_table.gui.location.destroy()
  player_table.gui = nil

  -- use update_filters to remove all stored filters for each group
  -- passing `nil` as the third argument will remove everything in that group
  -- in this case, you could also use `gui.remove_player_filters(player.index)` to accomplish the same thing
  gui.update_filters("inventory", player.index, nil, "remove")
  gui.update_filters("location", player.index, nil, "remove")
end

event.on_init(function()
  gui.init()
  gui.build_lookup_tables()

  -- players setup
  global.players = {}
  for i, player in pairs(game.players) do
    global.players[i] = {}
    create_guis(player)
  end
end)

event.on_load(function()
  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, {}) then
    gui.check_filter_validity()

    -- refresh all GUIs
    for i, player in pairs(game.players) do
      -- destroy and recreate GUIs
      -- destroying and recreating GUIs on a mod update is the best way to avoid edge cases
      destroy_guis(player, global.players[i])
      create_guis(player)
    end
  end
end)

-- this registers `gui.dispatch_handlers()` to all GUI events
gui.register_handlers()

-- if custom logic is needed, a handler may be overwritten after calling `gui.register_handlers()`
event.on_gui_click(function(e)
  -- dispatch_handlers - will run handlers for matched GUI filters, assigned using `handlers` in a GuiStructure
  -- the function will return whether or not a handler was dispatched
  if not gui.dispatch_handlers(e) then
    game.print("custom logic here")
  end
end)

-- create GUIs for any players that join
event.on_player_created(function(e)
  global.players[e.player_index] = {}
  local player = game.get_player(e.player_index)
  create_guis(player)
end)

-- remove global data and remove all filters for any players that leave
event.on_player_removed(function(e)
  global.players[e.player_index] = nil
  gui.remove_player_filters(e.player_index)
end)

-- update inventory GUI when the player's inventory changes
event.on_player_main_inventory_changed(function(e)
  local player = game.get_player(e.player_index)

  -- get the inventory table and its children
  local table = global.players[e.player_index].gui.inventory.slot_table
  local children = table.children

  -- iterate over the player's inventory contents
  local i = 0
  for name, count in pairs(player.get_main_inventory().get_contents()) do
    i = i + 1

    -- check for child - if it exists, just update it, otherwise create it
    local child = children[i]
    if child then
      child.sprite = "item/"..name
      child.number = count
    else
      table.add{
        type = "sprite-button",
        -- double underscore - only `demo_slot_button` will be matched, the rest will be ignored
        --[[
          this allows all generated inventory buttons to be assigned to the same handler, without needing to call
          `gui.build` on all of them
        ]]
        name = "demo_slot_button__"..i,
        style = "slot_button",
        sprite = "item/"..name,
        number = count
      }
    end
  end

  -- remove any extra buttons
  for j = i + 1, #children do
    children[j].destroy()
  end
end)