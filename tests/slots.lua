--- @param pane LuaGuiElement
--- @param prefix string
--- @param inset boolean
local function make_row(pane, prefix, inset)
  local panel
  if inset then
    panel = pane.add({ type = "frame", style = "slot_button_deep_frame" })
  else
    panel = pane.add({ type = "flow" })
  end
  panel.style.top_margin = 12
  local colors = { "default", "grey", "red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink" }
  for _, color in pairs(colors) do
    panel.add({ type = "sprite-button", style = prefix .. color, sprite = "item/stone-brick" })
  end
end

script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local frame = player.gui.screen.add({ type = "frame", name = "flib_test_frame", caption = "Slots" })
  frame.auto_center = true

  local inner = frame.add({ type = "frame", style = "inside_shallow_frame_with_padding", direction = "vertical" })
  inner.style.top_padding = 0

  make_row(inner, "flib_slot_", false)
  make_row(inner, "flib_selected_slot_", false)
  make_row(inner, "flib_slot_button_", true)
  make_row(inner, "flib_selected_slot_button_", true)
  make_row(inner, "flib_standalone_slot_button_", false)
  make_row(inner, "flib_selected_standalone_slot_button_", false)
end)
