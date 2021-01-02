local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local migration = require("__flib__.migration")
local mod_gui = require("__core__.lualib.mod-gui")

-- create the GUIs
local function create_guis(player)
  -- location button - kept in the `mod-gui` button flow
  -- here we demonstrate a method of using action messages on elements without using `gui.build()`
  local location_button = mod_gui.get_button_flow(player).add{
    type = "button",
    style = mod_gui.button_style,
    caption = "0, 0",
    tags = {
      -- the module's tags function read to and write from this subtable, keyed by the active mod's name
      [script.mod_name] = {
        -- actions are kept in the `flib` subtable
        flib = {
          -- abbreviated GUI event name -> action message (can be anything that is truthy)
          on_click = "recenter_inventory_gui"
        }
      }
    }
  }

  -- it is a good idea to extract commonly-used elements to builder functions
  local function frame_action_button(to_print)
    return {
      type = "sprite-button",
      style = "frame_action_button",
      -- adding tags to an element during gui.build() will automatically stick them in the `script.mod_name` subtable
      tags = {to_print = to_print},
      actions = {
        on_click = "print_titlebar_click"
      }
    }
  end

  -- inventory GUI - kept in `screen`
  local inventory_refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      -- array of table keys defining a path to keep a reference to the frame LuaGuiElement
      ref = {"window"},
      -- table of abbreviated GUI event name -> action message (can be anything that is truthy)
      actions = {
        on_location_changed = "update_location_string"
      },
      children = {
        {type = "flow", ref = {"titlebar", "flow"}, children = {
          {type = "label", style = "frame_title", caption = "Demo GUI", ignored_by_interaction = true},
          {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
          -- call builder functions for commonly-used elements
          frame_action_button("left"),
          frame_action_button("center"),
          frame_action_button("right")
        }},
        -- style mods - change style properties on an element immediately after creation
        -- available properties are listen in the LuaStyle docs
        {type = "frame", style = "inside_shallow_frame_with_padding", style_mods = {padding = 12}, children = {
          {type = "frame", style = "slot_button_deep_frame", children = {
            {
              type = "scroll-pane",
              style = "flib_naked_scroll_pane_no_padding",
              style_mods = {height = 200},
              children = {
                {
                  type = "table",
                  style = "slot_table",
                  style_mods = {width = 400},
                  column_count = 10,
                  ref = {"slot_table"}
                }
              }
            }
          }}
        }}
      }
    }
  })

  -- inventory_refs was built using the structure defined in the `ref` keys
  -- the titlebar flow was saved to the `titlebar` subtable
  inventory_refs.titlebar.flow.drag_target = inventory_refs.window
  inventory_refs.window.force_auto_center()

  global.players[player.index].guis = {inventory = inventory_refs, location = location_button}
end

local function destroy_guis(player_table)
  -- destroy parents for both GUIs and clean up tables
  player_table.guis.inventory.window.destroy()
  player_table.guis.location.destroy()
  player_table.guis = nil
end

-- handle actions for both GUIs
-- in a mod with multiple large GUIs, it is usually a good idea to have separate handler functions for each GUI
local function handle_action(msg, e)
  if msg == "print_titlebar_click" then
    -- use `gui.get_tags()` to automatically access the `script.mod_name` subtable
    local side = gui.get_tags(e.element).to_print
    game.get_player(e.player_index).print("You clicked the "..side.." titlebar button!")
  elseif msg == "print_sprite_click" then
    local _, _, name = string.find(e.element.sprite, "item/(.*)")
    game.get_player(e.player_index).print("You clicked the "..name.." slot button!")
  elseif msg == "update_location_string" then
    local location = e.element.location
    global.players[e.player_index].guis.location.caption = location.x..", "..location.y
  elseif msg == "recenter_inventory_gui" then
    global.players[e.player_index].guis.inventory.window.force_auto_center()
  end
end

event.on_init(function()
  -- players setup
  global.players = {}
  for i, player in pairs(game.players) do
    global.players[i] = {}
    create_guis(player)
  end
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, {}) then
    -- refresh all GUIs
    for i, player in pairs(game.players) do
      -- destroy and recreate GUIs
      -- destroying and recreating GUIs on a mod update is the best way to avoid edge cases
      destroy_guis(global.players[i])
      create_guis(player)
    end
  end
end)

-- this function will be hooked to all `on_gui_*` events
gui.hook_events(function(e)
  -- read the corresponding action from the element's tags
  local msg = gui.read_action(e)
  -- if an action was found
  if msg then
    -- if your mod has multiple GUIs, here is where you would check which GUI the action is for, and call the
    -- appropriate handler function
    handle_action(msg, e)
  -- custom logic may be needed in some cases where action messages are unusable
  elseif e.name == defines.events.on_gui_closed and e.gui_type == 16 then
    -- custom logic here
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
end)

-- update inventory GUI when the player's inventory changes
event.on_player_main_inventory_changed(function(e)
  local player = game.get_player(e.player_index)

  -- get the inventory table and its children
  local table = global.players[e.player_index].guis.inventory.slot_table
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
        style = "slot_button",
        sprite = "item/"..name,
        number = count,
        -- another example if using element actions outside of `gui.build`
        tags = {
          [script.mod_name] = {
            flib = {
              on_click = "print_sprite_click"
            }
          }
        }
      }
    end
  end

  -- remove any extra buttons
  for j = i + 1, #children do
    children[j].destroy()
  end
end)
