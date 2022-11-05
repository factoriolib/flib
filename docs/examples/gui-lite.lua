local event = require("__flib__.event")
local gui = require("__flib__.gui-lite")

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

gui.handle_events()

event.on_init(function()
  global.guis = {}
end)

event.on_player_created(function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]

  local refs = gui.add(player.gui.screen, {
    {
      type = "frame",
      name = "flib_demo_window",
      direction = "vertical",
      handler = { [defines.events.on_gui_closed] = handlers.window_closed },
      {
        type = "flow",
        name = "titlebar_flow",
        style = "flib_titlebar_flow",
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
    },
  })

  refs.flib_demo_window.force_auto_center()
  refs.titlebar_flow.drag_target = refs.flib_demo_window

  player.opened = refs.flib_demo_window

  global.guis[e.player_index] = {
    player = player,
    refs = refs,
  }
end)
