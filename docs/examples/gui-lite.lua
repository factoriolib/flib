local gui = require("__flib__/gui-lite")

-- Place the GUI handlers in a table so they can be easily passed into 'gui.add_handlers'
local handlers = {}

--- @param e on_gui_click
function handlers.close_button(e)
  local player = game.get_player(e.player_index)
  player.opened = nil
end

--- @param e on_gui_closed
function handlers.window_closed(e)
  e.element.destroy()
end

gui.add_handlers(handlers)

-- Handle all 'on_gui_*' events
gui.handle_events()

-- Create the GUI when a player is created
script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]

  local _, window = gui.add(player.gui.screen, {
    type = "frame",
    name = "flib_demo_window",
    direction = "vertical",
    elem_mods = { auto_center = true },
    handler = { [defines.events.on_gui_closed] = handlers.window_closed },
    {
      type = "flow",
      style = "flib_titlebar_flow",
      drag_target = "flib_demo_window",
      { type = "label", style = "frame_title", caption = "flib GUI demo", ignored_by_interaction = true },
      { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
      {
        type = "sprite-button",
        style = "frame_action_button",
        sprite = "utility/close_white",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        handler = handlers.close_button,
      },
    },
    { type = "frame", style = "inside_shallow_frame_with_padding", style_mods = { width = 400, height = 400 } },
  })

  player.opened = window
end)
