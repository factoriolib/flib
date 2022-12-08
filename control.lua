local flib_gui = require("__flib__/gui-lite")
local math = require("__flib__/math")
local flib_position = require("__flib__/position")

flib_gui.handle_events()

--- @param parent LuaGuiElement
--- @param element LuaGuiElement
--- @param index uint
local function move_to(parent, element, index)
  game.print(index)
  index = math.min(index, #parent.children)
  local temp = parent.add({ type = "empty-widget", index = index + 1 })
  parent.swap_children(element.get_index_in_parent(), temp.get_index_in_parent())
  temp.destroy()
end

--- @type table<string, fun(player: LuaPlayer, e: GuiEventData)
local handlers

handlers = {
  on_location_changed = function(player, e)
    if not global.offset then
      return
    end
    global.offset = flib_position.sub(e.element.location, global.initial_location)
    e.element.location = global.initial_location
    local offset = math.round(global.offset.y / 36)
    if global.initial_index + offset ~= global.frame.get_index_in_parent() then
      move_to(player.gui.screen.flib_test.content, global.frame, global.initial_index + offset)
    end
  end,
  on_drag_handle_click = function(player, e)
    local position = e.element.tags.position
    if not position then
      return
    end
    -- create_overlay(player)
    local window = player.gui.screen.flib_test --[[@as LuaGuiElement]]
    global.initial_location = window.location
    global.offset = { x = 0, y = 0 }
    global.frame = e.element.parent
    global.initial_index = e.element.parent.get_index_in_parent()
  end,
}

flib_gui.add_handlers(handlers, function(e, handler)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  handler(player, e)
end)

script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]

  local subframes = {}
  for i = 1, 5 do
    table.insert(subframes, {
      type = "frame",
      style = "train_schedule_station_frame",
      {
        type = "empty-widget",
        style = "draggable_space_in_train_schedule",
        style_mods = { vertically_stretchable = true },
        drag_target = "flib_test",
        tags = { position = i },
        handler = handlers.on_drag_handle_click,
      },
      { type = "label", caption = i },
    })
  end

  flib_gui.add(player.gui.screen, {
    type = "frame",
    name = "flib_test",
    caption = "Test",
    elem_mods = { auto_center = true },
    handler = { [defines.events.on_gui_location_changed] = handlers.on_location_changed },
    {
      type = "frame",
      name = "content",
      style = "inside_deep_frame",
      direction = "vertical",
      children = subframes,
    },
  })
end)
