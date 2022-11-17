-- ---------------------------------------------------------------------------------------------------------------------
-- GUI MODULE EXAMPLE CODE
-- This is an implementation of TodoMVC using flib's GUI module. As such, it is not a small piece of code, but it
-- provides a great demonstration of various aspects of the GUI module. Dropping this into the `control.lua` file of an
-- empty mod will allow you to interact with the resulting GUI.
--
-- The code is split into two sections:
-- "GUI Code" is the contents of the `todo_gui` object. This code would usually go into its own file and return the
-- `todo_gui` object at the end. However, for the sake of the example, it has been inlined into one file.
-- "Event Handlers" contains what would go in the `control.lua` file. It passes events to the GUI module, creates the
-- GUI itself, and demonstrates some of the control flow involved.
-- ---------------------------------------------------------------------------------------------------------------------

local event = require("__flib__/event")
local gui = require("__flib__/gui")
local mod_gui = require("__core__/lualib/mod-gui")
local table = require("__flib__/table")

-- ---------------------------------------------------------------------------------------------------------------------
-- GUI CODE

local todo_gui = {}

local view_modes = table.invert({
  "all",
  "active",
  "completed",
})

-- ROOT

local function update_mode_radios(gui_data)
  local mode = gui_data.state.mode
  local subfooter_flow = gui_data.refs.subfooter_flow

  subfooter_flow.all_radiobutton.state = mode == view_modes.all
  subfooter_flow.active_radiobutton.state = mode == view_modes.active
  subfooter_flow.completed_radiobutton.state = mode == view_modes.completed
end

local function update_todos(gui_data)
  local state = gui_data.state
  local refs = gui_data.refs

  local todos_flow = refs.todos_flow
  local children = todos_flow.children
  local i = 0
  local active_count = 0
  local completed_count = 0
  for id, todo in pairs(state.todos) do
    if todo.completed then
      completed_count = completed_count + 1
    else
      active_count = active_count + 1
    end

    if
      state.mode == view_modes.all
      or (state.mode == view_modes.active and not todo.completed)
      or (state.mode == view_modes.completed and todo.completed)
    then
      i = i + 1
      local child = children[i]
      if child then
        gui.update(child, {
          {
            elem_mods = { caption = todo.text, state = todo.completed },
            tags = { todo_id = id },
          },
          {},
          { tags = { todo_id = id } },
        })
      else
        gui.add(todos_flow, {
          type = "flow",
          style_mods = { vertical_align = "center" },
          {
            type = "checkbox",
            caption = todo.text,
            state = todo.completed,
            actions = {
              on_click = "toggle_completed",
            },
            tags = { todo_id = id },
          },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
          {
            type = "sprite-button",
            style = "tool_button_red",
            sprite = "utility/trash",
            tooltip = "Delete",
            actions = {
              on_click = "delete_todo",
            },
            tags = { todo_id = id },
          },
        })
      end
    end
  end
  for j = i + 1, #children do
    children[j].destroy()
  end

  if i == 0 then
    todos_flow.visible = false
  else
    todos_flow.visible = true
  end

  if next(state.todos) then
    refs.subfooter_frame.visible = true
  else
    refs.subfooter_frame.visible = false
  end

  refs.subfooter_flow.items_left_label.caption = active_count .. " items left"
  refs.subfooter_flow.clear_completed_button.enabled = completed_count > 0
end

function todo_gui.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      ref = { "window" },
      actions = {
        on_closed = "close",
      },
      {
        type = "flow",
        ref = { "titlebar_flow" },
        children = {
          { type = "label", style = "frame_title", caption = "TodoMVC", ignored_by_interaction = true },
          { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
          {
            type = "sprite-button",
            style = "frame_action_button",
            sprite = "utility/close_white",
            hovered_sprite = "utility/close_black",
            clicked_sprite = "utility/close_black",
            mouse_button_filter = { "left" },
            actions = {
              on_click = "close",
            },
          },
        },
      },
      {
        type = "frame",
        style = "inside_shallow_frame",
        direction = "vertical",
        {
          type = "textfield",
          style_mods = { width = 500, margin = 12 },
          ref = { "textfield" },
          actions = {
            on_confirmed = "add_todo",
          },
        },
        {
          type = "flow",
          style_mods = { left_margin = 12, right_margin = 12, bottom_margin = 12 },
          direction = "vertical",
          elem_mods = { visible = false },
          ref = { "todos_flow" },
        },
        {
          type = "frame",
          style = "subfooter_frame",
          elem_mods = { visible = false },
          ref = { "subfooter_frame" },
          {
            type = "flow",
            style_mods = { vertical_align = "center", left_margin = 8 },
            ref = { "subfooter_flow" },
            { type = "label", name = "items_left_label", caption = "0 items left" },
            { type = "empty-widget", style = "flib_horizontal_pusher" },
            {
              type = "radiobutton",
              name = "all_radiobutton",
              caption = "All",
              state = true,
              actions = {
                on_checked_state_changed = "change_mode",
              },
              tags = { mode = view_modes.all },
            },
            {
              type = "radiobutton",
              name = "active_radiobutton",
              caption = "Active",
              state = false,
              actions = {
                on_checked_state_changed = "change_mode",
              },
              tags = { mode = view_modes.active },
            },
            {
              type = "radiobutton",
              name = "completed_radiobutton",
              caption = "Completed",
              state = false,
              actions = {
                on_checked_state_changed = "change_mode",
              },
              tags = { mode = view_modes.completed },
            },
            { type = "empty-widget", style = "flib_horizontal_pusher" },
            {
              type = "button",
              name = "clear_completed_button",
              caption = "Clear completed",
              elem_mods = { enabled = false },
              actions = {
                on_click = "delete_completed_todos",
              },
            },
          },
        },
      },
    },
  })

  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()
  player.opened = refs.window

  player_table.todo = {
    refs = refs,
    state = {
      mode = view_modes.all,
      next_id = 1,
      todos = {},
      visible = false,
    },
  }
end

function todo_gui.open(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.todo

  gui_data.refs.window.visible = true
  player.opened = gui_data.refs.window
end

function todo_gui.close(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.todo

  gui_data.refs.window.visible = false
  if player.opened then
    player.opened = nil
  end
end

-- ACTION HANDLERS

local function add_todo(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.todo
  local state = gui_data.state

  local todo_text = e.element.text

  state.todos[state.next_id] = {
    completed = false,
    text = todo_text,
  }

  state.next_id = state.next_id + 1

  e.element.text = ""

  update_todos(gui_data)
end

local function toggle_todo_completed(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.todo
  local state = gui_data.state

  local todo_data = state.todos[gui.get_tags(e.element).todo_id]
  todo_data.completed = e.element.state

  update_todos(gui_data)
end

local function delete_todo(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.todo
  local state = gui_data.state

  state.todos[gui.get_tags(e.element).todo_id] = nil

  update_todos(gui_data)
end

local function delete_completed_todos(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.todo
  local state = gui_data.state

  for id, todo in pairs(state.todos) do
    if todo.completed then
      state.todos[id] = nil
    end
  end

  update_todos(gui_data)
end

local function change_view_mode(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.todo
  local state = gui_data.state

  state.mode = gui.get_tags(e.element).mode

  update_mode_radios(gui_data)
  update_todos(gui_data)
end

todo_gui.actions = {
  close = todo_gui.close,
  add_todo = add_todo,
  toggle_completed = toggle_todo_completed,
  delete_todo = delete_todo,
  delete_completed_todos = delete_completed_todos,
  change_mode = change_view_mode,
}

-- ---------------------------------------------------------------------------------------------------------------------
-- EVENT HANDLERS

event.on_init(function()
  global.players = {}
end)

event.on_player_created(function(e)
  -- Create player table
  global.players[e.player_index] = {}
  local player_table = global.players[e.player_index]

  local player = game.get_player(e.player_index)

  -- CREATE GUIS

  gui.add(mod_gui.get_button_flow(player), {
    type = "button",
    style = mod_gui.button_style,
    caption = "TodoMVC",
    actions = {
      on_click = "toggle_todo_gui",
    },
  })

  todo_gui.build(player, player_table)
end)

local function toggle_todo_gui(e)
  local player_table = global.players[e.player_index]
  local visible = player_table.todo.refs.window.visible
  if visible then
    todo_gui.close(e)
  else
    todo_gui.open(e)
  end
end

gui.hook_events(function(e)
  local action = gui.read_action(e)
  if action then
    if action == "toggle_todo_gui" then
      toggle_todo_gui(e)
    else
      todo_gui.actions[action](e)
    end
  end
end)
