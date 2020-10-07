--- A GUI library inspired by Elm and Seed-RS.
-- @module gui
-- @alias flib_gui
local flib_gui = {}

-- CONSTANTS

local event_keys = {}
for key, id in pairs(defines.events) do
  if string.find(key, "gui") then
    event_keys[string.gsub(key, "_gui", "")] = id
  end
end

local elem_functions = {
  clear_items = true,
  -- get_item = true,
  set_item = true,
  add_item = true,
  remove_item = true,
  -- get_slider_minimum = true,
  -- get_slider_maximum = true,
  -- get_slider_minimum_maximum = true,
  -- get_slider_value_step = true,
  -- get_slider_discrete_slider = true,
  -- get_slider_discrete_values = true,
  focus = true,
  scroll_to_top = true,
  scroll_to_bottom = true,
  scroll_to_left = true,
  scroll_to_right = true,
  scroll_to_element = true,
  select_all = true,
  select = true,
  -- add_tab = true,
  -- remove_tab = true,
  force_auto_center = true,
  scroll_to_item = true
}

local elem_style_keys = {
  -- gui = {readOnly = true},
  -- name = {readOnly = true},
  minimal_width = {},
  maximal_width = {},
  minimal_height = {},
  maximal_height = {},
  natural_width = {},
  natural_height = {},
  top_padding = {},
  right_padding = {},
  bottom_padding = {},
  left_padding = {},
  top_margin = {},
  right_margin = {},
  bottom_margin = {},
  left_margin = {},
  horizontal_align = {},
  vertical_align = {},
  font_color = {},
  font = {},
  top_cell_padding = {},
  right_cell_padding = {},
  bottom_cell_padding = {},
  left_cell_padding = {},
  horizontally_stretchable = {},
  vertically_stretchable = {},
  horizontally_squashable = {},
  vertically_squashable = {},
  rich_text_setting = {},
  hovered_font_color = {},
  clicked_font_color = {},
  disabled_font_color = {},
  pie_progress_color = {},
  clicked_vertical_offset = {},
  selected_font_color = {},
  selected_hovered_font_color = {},
  selected_clicked_font_color = {},
  strikethrough_color = {},
  horizontal_spacing = {},
  vertical_spacing = {},
  use_header_filler = {},
  color = {},
  -- column_alignments = {readOnly = true},
  single_line = {},
  extra_top_padding_when_activated = {},
  extra_bottom_padding_when_activated = {},
  extra_left_padding_when_activated = {},
  extra_right_padding_when_activated = {},
  extra_top_margin_when_activated = {},
  extra_bottom_margin_when_activated = {},
  extra_left_margin_when_activated = {},
  extra_right_margin_when_activated = {},
  stretch_image_to_widget_size = {},
  badge_font = {},
  badge_horizontal_spacing = {},
  default_badge_font_color = {},
  selected_badge_font_color = {},
  disabled_badge_font_color = {},
  width = {write_only = true},
  height = {write_only = true},
  padding = {write_only = true},
  margin = {write_only = true}
}

-- FIELDS

local guis = {}
local gui_mts = {}

-- HELPER FUNCTIONS

local function get_or_create_player_table(player_index)
  local players = global.__flib.gui.players
  local player_table = players[player_index]
  if player_table then
    return player_table
  else
    players[player_index] = {
      guis = {
        __nextindex = 1
      }
    }
    return players[player_index]
  end
end

-- BUILDING AND DIFFING

--[[
  if element tags are added:

  local tags = elem.tags[mod_name]
  if tags and type(value) == "table" and value.__deleted then
    tags[event_id] = nil
  else
    local info = {gui_index = self.gui_index, msg = value}
    if tags then
      local event_info = tags[event_id]
      if event_info then
        local event_msg = event_info.msg
        for k, v in pairs(value) do
          event_msg[k] = v
        end
      else
        tags[event_id] = info
      end
    else
      elem.tags[mod_name] = {[event_id] = info}
    end
  end
]]

local function apply_view(self, parent, index, view)
  local children = parent.children
  local elem = children[index]

  -- destroy and recreate if the type changed
  if elem and view.type and view.type ~= elem.type then
    -- TODO insert instead, if the capability is ever added to the API :(
    -- delete this and all elements after this
    for i = index, #children do
      children[i].destroy()
    end
    elem = nil
  end

  -- add a new element if the current one doesn't exist or was deleted
  if not elem then
    elem = parent.add(view)
  end

  -- iterate keys
  for key, value in pairs(view) do
    if key ~= "type" and key ~= "name" and key ~= "children" then
      local event_id = event_keys[key]
      if elem_style_keys[key] then
        elem.style[key] = value
      elseif elem_functions[key] then
        elem[key](table.unpack(value))
      elseif event_id then

      else
        elem[key] = value
      end
    end
  end

  -- process children
  local elem_children = elem.children
  for child_index, child_view in pairs(view.children or {}) do
    if child_view.__removed then
      -- delete the element
      elem_children[child_index].destroy()
    else
      -- update the element
      apply_view(self, elem, child_index, child_view)
    end
  end
  return elem
end

--[[

DIFF LOGIC:
- `old` will be updated in-place to avoid the need for deepcopying
- if a property was added in `new`, add it to `old`
- if a property was removed in `new`, change it to `{__removed = true}` in `old`
- if a property was changed in `new`, set it to that value in `old`
- if a child's type changes, then it and every child after it will remain untouched, as new elements will need to be
  created from scratch (no insertion)
]]

local function diff(old, new)
  for key, value in pairs(new) do
    local old_value = old[key]
    if old_value and type(old_value) == "table" and type(value) == "table" then
      diff(old_value, value)
      -- TODO find a more performant way to do this
      if table_size(old_value) == 0 then
        old[key] = nil
      end
    elseif old_value ~= value then
      old[key] = value
    else
      old[key] = nil
    end
  end
  for key in pairs(old) do
    local new_value = new[key]
    if not new_value then
      old[key] = {__removed = true}
    end
  end
end

-- GUI "INSTANCE"

local GuiInstance = {}

-- update the state, generate a new view, diff it, and apply the results
function GuiInstance:update(msg, e)
  local self_obj = guis[self.gui_name]
  self_obj.update(self.state, msg, e)

  local new_view = self_obj.view(self.state)

  -- TODO
  -- the stored `last_view` will be modified and consumed to become the diff, in order to avoid deepcopying
  local last_view = self.last_view
  diff(last_view, new_view)
  apply_view(self, self.parent, self.root_child_index, last_view)

  -- save the new view as the last view for future diffing
  self.last_view = new_view
end

-- destroy the instance and clean up handlers
function GuiInstance:destroy()
  local player_table = get_or_create_player_table(self.player_index)
  local player_guis = player_table.guis

  self.root.destroy()

  player_guis[self.gui_index] = nil
end

-- GUI "ROOT"

local GuiRoot = {}

-- create an instance of this GUI
function GuiRoot:create(parent, ...)
  local player_index = parent.player_index or parent.player.index
  local player_table = get_or_create_player_table(player_index)
  local player_guis = player_table.guis

  local initial_state = self.init(player_index, ...)

  if type(initial_state) ~= "table" then
    error("State must be a table.")
  end

  local index = player_guis.__nextindex

  local initial_view = self.view(initial_state)

  local instance = {
    gui_index = index,
    gui_name = self.name,
    last_view = initial_view,
    parent = parent,
    player_index = player_index,
    root_child_index = #parent.children + 1,
    state = initial_state,
  }

  setmetatable(instance, {__index = GuiInstance})

  player_guis[index] = instance
  player_guis.__nextindex = index + 1

  -- we are creating the GUI from nothing, so no diffing is needed
  -- save the root element so it can be destroyed later
  instance.root = apply_view(instance, parent, #parent.children + 1, initial_view)

  return instance
end

-- PUBLIC FUNCTIONS

--- Initial setup.
--
-- Must be called during `on_init` **before** any GUIs are built.
function flib_gui.init()
  if global.__flib then
    global.__flib.gui = {players = {}}
  else
    global.__flib = {
      gui = {players = {}}
    }
  end
end

--- Restore metatables on all GUI instances.
--
-- Must be called during `on_load`.
function flib_gui.load()
  for _, player_table in pairs(global.__flib.gui.players) do
    for key, gui_data in pairs(player_table.guis) do
      if key ~= "__nextindex" then
        local gui_mt = gui_mts[gui_data.gui_name]
        -- if the GUI object no longer exists, then the mod version changed and things will get cleaned up anyway
        if gui_mt then
          setmetatable(gui_data, {__index = GuiInstance})
        end
      end
    end
  end
end

--- Create a new GUI object.
--
-- This sets up the instance metatable for this GUI and adds the `create()` function to the object.
-- @tparam string name The name of the GUI. Must be unique.
-- @treturn table The newly created GUI object. Add your `init()`, `update()` and `view()` functions to this object
-- before returning it.
-- @usage
-- local my_gui = gui.new("my_gui")
function flib_gui.new(name)
  if guis[name] then
    error("Duplicate GUI name ["..name.."] - every GUI must have a unique name.")
  end

  local obj = {name = name}

  setmetatable(obj, {__index = GuiRoot})

  guis[name] = obj

  return obj
end

return flib_gui