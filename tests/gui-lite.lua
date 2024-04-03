-- TodoMVC implementation using gui-lite.
-- The following is how I (raiguard) prefer to structure GUIs, but it is not the only way.

-- GUI

local flib_gui = require("__flib__.gui-lite")
local mod_gui = require("__core__.lualib.mod-gui")

--- @alias FlibTestGuiMode
--- | "all"
--- | "active"
--- | "completed"

--- @class FlibTestGui
--- @field elems table<string, LuaGuiElement>
--- @field player LuaPlayer
--- @field completed_count integer
--- @field items_left integer
--- @field mode FlibTestGuiMode
--- @field pinned boolean

--- @class FlibTestGuiBase
local gui = {}

--- @param name string
--- @param sprite string
--- @param tooltip LocalisedString
--- @param handler function
local function frame_action_button(name, sprite, tooltip, handler)
  return {
    type = "sprite-button",
    name = name,
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    handler = handler,
  }
end

--- Build the GUI for the given player.
--- @param player LuaPlayer
function gui.build(player)
  -- `elems` is a table consisting of all GUI elements that were given names, keyed by their name.
  -- `window` is the GUI element that was created first, which in this case, was the top-level frame.
  -- The second argument can be a single element or an array of elements. Here we pass a single element.
  local elems = flib_gui.add(player.gui.screen, {
    type = "frame",
    name = "flib_todo_window",
    direction = "vertical",
    -- Use `elem_mods` to make modifications to the GUI element after creation.
    --- @diagnostic disable-next-line: missing-fields
    elem_mods = { auto_center = true },
    -- If `handler` is a function, it will call that function for any GUI event on this element.
    -- If it is a dictioanry of event -> function, it will call the corresponding function for the corresponding event.
    handler = { [defines.events.on_gui_closed] = gui.on_window_closed },
    -- Children can be defined as array members of an element.
    {
      type = "flow",
      style = "flib_titlebar_flow",
      -- The string must be the name of an element that is present in the `elems` table. To set drag_target to a
      -- LuaGuiElement reference, do so inside of the `elem_mods` table.
      drag_target = "flib_todo_window",
      -- For a real mod, you would want to use localised strings for the captions. They are omitted here to keep this
      -- demo in one file.
      { type = "label", style = "frame_title", caption = "TodoMVC", ignored_by_interaction = true },
      { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
      -- You can use helper functions for repetitive elements.
      frame_action_button("pin_button", "flib_pin", { "gui.flib-keep-open" }, gui.toggle_pinned),
      frame_action_button("close_button", "utility/close", { "gui.close-instruction" }, gui.hide),
    },
    {
      type = "frame",
      style = "inside_shallow_frame",
      -- Use `style_mods` to make modifications to the element's style.
      --- @diagnostic disable-next-line: missing-fields
      style_mods = { width = 500 },
      direction = "vertical",
      {
        type = "frame",
        style = "subheader_frame",
        {
          type = "textfield",
          name = "textfield",
          style = "flib_widthless_textfield",
          style_mods = { horizontally_stretchable = true },
          handler = {
            -- Multiple different event handlers
            [defines.events.on_gui_confirmed] = gui.on_textfield_confirmed,
            [defines.events.on_gui_text_changed] = gui.on_textfield_text_changed,
          },
          {
            type = "label",
            name = "placeholder",
            style_mods = { font_color = { a = 0.4 } },
            caption = "What needs to be done?",
            ignored_by_interaction = true,
          },
        },
      },
      {
        type = "scroll-pane",
        style = "flib_naked_scroll_pane_no_padding",
        style_mods = { maximal_height = 400 },
        -- We use a flow here to allow customizing the vertical spacing with style_mods. Normally you want to use a data
        -- stage style on the scroll-pane for this.
        {
          type = "flow",
          name = "todos_flow",
          style_mods = { vertical_spacing = 8, padding = 12 },
          direction = "vertical",
        },
      },
      {
        type = "frame",
        name = "subfooter",
        style = "subfooter_frame",
        {
          type = "flow",
          style = "centering_horizontal_flow",
          { type = "label", name = "count_label", style_mods = { left_margin = 8 }, caption = "0 items left" },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
          {
            type = "flow",
            style_mods = { horizontal_spacing = 8 },
            {
              type = "radiobutton",
              name = "all_radio",
              caption = "All",
              state = true,
              -- Element tags can be specified like this.
              tags = { mode = "all" },
              handler = { [defines.events.on_gui_checked_state_changed] = gui.change_mode },
            },
            {
              type = "radiobutton",
              name = "active_radio",
              caption = "Active",
              state = false,
              tags = { mode = "active" },
              handler = { [defines.events.on_gui_checked_state_changed] = gui.change_mode },
            },
            {
              type = "radiobutton",
              name = "completed_radio",
              caption = "Completed",
              state = false,
              tags = { mode = "completed" },
              handler = { [defines.events.on_gui_checked_state_changed] = gui.change_mode },
            },
          },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
          {
            type = "button",
            name = "clear_completed_button",
            caption = "Clear completed",
            enabled = false,
            -- Because on_gui_click is the only event related to buttons, we can take a shortcut.
            handler = gui.clear_completed,
          },
        },
      },
    },
  })

  -- In a real mod, you would want to initially hide the GUI and not set opened until the player opens it.
  player.opened = elems.flib_todo_window

  --- @type FlibTestGui
  global.guis[player.index] = {
    elems = elems,
    player = player,
    -- State variables
    completed_count = 0,
    items_left = 0,
    mode = "all",
    pinned = false,
  }
end

--- @param e EventData.on_gui_confirmed
function gui.on_textfield_text_changed(_, e)
  if #e.element.text == 0 then
    e.element.placeholder.visible = true
  else
    e.element.placeholder.visible = false
  end
end

--- @param self FlibTestGui
--- @param e EventData.on_gui_checked_state_changed
function gui.change_mode(self, e)
  local mode = e.element.tags.mode --[[@as FlibTestGuiMode]]
  self.mode = mode
  self.elems.all_radio.state = mode == "all"
  self.elems.active_radio.state = mode == "active"
  self.elems.completed_radio.state = mode == "completed"
  -- Adjust checkbox visibility
  for _, checkbox in pairs(self.elems.todos_flow.children) do
    checkbox.visible = (checkbox.state and mode ~= "active") or (not checkbox.state and mode ~= "completed")
  end
end

--- @param self FlibTestGui
function gui.clear_completed(self)
  for _, checkbox in pairs(self.elems.todos_flow.children) do
    if checkbox.state then
      checkbox.destroy()
    end
  end
  self.completed_count = 0
  gui.update_footer(self)
end

--- @param self FlibTestGui
function gui.hide(self)
  self.elems.flib_todo_window.visible = false
end

--- @param self FlibTestGui
--- @param e EventData.on_gui_checked_state_changed
function gui.on_todo_toggled(self, e)
  local checkbox = e.element
  if checkbox.state then
    -- Hide this item if needed
    if self.mode == "active" then
      checkbox.visible = false
    end
    -- Decrement items left counter
    self.items_left = self.items_left - 1
    self.completed_count = self.completed_count + 1
  else
    self.items_left = self.items_left + 1
    self.completed_count = self.completed_count - 1
  end
  gui.update_footer(self)
end

--- @param self FlibTestGui
--- @param e EventData.on_gui_confirmed
function gui.on_textfield_confirmed(self, e)
  local title = e.element.text
  if #title == 0 then
    self.player.play_sound({ path = "utility/cannot_build" })
    return
  end
  local todos_flow = self.elems.todos_flow
  flib_gui.add(todos_flow, {
    type = "checkbox",
    --- @diagnostic disable-next-line: missing-fields
    style_mods = { horizontally_stretchable = true },
    caption = title,
    state = false,
    visible = self.mode ~= "completed",
    handler = { [defines.events.on_gui_checked_state_changed] = gui.on_todo_toggled },
  })
  self.items_left = self.items_left + 1
  e.element.text = ""
  -- The above line doesn't fire the on_gui_text_changed event, so call its handler manually.
  -- The event table isn't actually the right type, but it has the same info, so it's fine.
  gui.on_textfield_text_changed(self, e)
  gui.update_footer(self)
end

--- @param self FlibTestGui
function gui.on_window_closed(self)
  -- Don't close when enabling the pin
  if self.pinned then
    return
  end
  gui.hide(self)
end

--- @param self FlibTestGui
function gui.show(self)
  self.elems.flib_todo_window.visible = true
  self.elems.textfield.focus()
  if not self.pinned then
    self.player.opened = self.elems.flib_todo_window
  end
end

--- @param self FlibTestGui
function gui.toggle_pinned(self)
  -- "Pinning" the GUI will remove it from player.opened, allowing it to coexist with other windows.
  -- I highly recommend implementing this for your GUIs. flib includes the requisite sprites and locale for the button.
  self.pinned = not self.pinned
  if self.pinned then
    self.elems.close_button.tooltip = { "gui.close" }
    self.elems.pin_button.sprite = "flib_pin_black"
    self.elems.pin_button.style = "flib_selected_frame_action_button"
    if self.player.opened == self.elems.flib_todo_window then
      self.player.opened = nil
    end
  else
    self.elems.close_button.tooltip = { "gui.close-instruction" }
    self.elems.pin_button.sprite = "flib_pin_white"
    self.elems.pin_button.style = "frame_action_button"
    self.player.opened = self.elems.flib_todo_window
  end
end

--- @param self FlibTestGui
function gui.toggle_visible(self)
  if self.elems.flib_todo_window.visible then
    gui.hide(self)
  else
    gui.show(self)
  end
end

--- @param self FlibTestGui
function gui.update_footer(self)
  self.elems.count_label.caption = self.items_left .. " items left"
  self.elems.clear_completed_button.enabled = self.completed_count > 0
end

-- Add all functions in the `gui` table as callable handlers. This is required in order for functions in `gui.add` to
-- work. For convenience, flib will ignore any value that isn't a function.
-- The second argument is an optional wrapper function that will be called in lieu of the specified handler of an
-- element. It is used in this case to get the GUI table for the corresponding player before calling the handler.
flib_gui.add_handlers(gui, function(e, handler)
  local self = global.guis[e.player_index]
  if self then
    handler(self, e)
  end
end)

-- BOOTSTRAP

-- Handle all 'on_gui_*' events with `flib_gui.dispatch`. If you don't call this, then your element handlers won't work!
-- If you wish to have custom logic for a specific GUI event, you can call `flib_gui.dispatch` yourself in your main
-- event handler. `handle_events` will not override any existing event handlers.
flib_gui.handle_events()

-- Initalize guis table
script.on_init(function()
  global.guis = {}
end)

-- Create the GUI when a player is created
script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  gui.build(player)
  -- Add mod_gui button
  local button_flow = mod_gui.get_button_flow(player) --[[@as LuaGuiElement]]
  flib_gui.add(button_flow, {
    type = "button",
    style = mod_gui.button_style,
    caption = "TodoMVC",
    handler = gui.toggle_visible,
  })
end)

-- For a real mod, you would also want to handle on_configuration_changed to rebuild your GUIs, and on_player_removed
-- to remove the GUI table from global. You would also want to ensure that the GUI is valid before running methods.
-- For the sake of brevity, these things were not covered in this demo.
