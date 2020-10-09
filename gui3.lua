--- A GUI library inspired by Elm and Seed-RS.
-- @module gui
-- @alias flib_gui
local flib_gui = {}

-- CONSTANTS

local event_keys = {}
for key, id in pairs(defines.events) do
  if string.find(key, "gui") then
    event_keys[string.gsub(key, "_gui", "")] = tostring(id)
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

local elem_read_only_keys = {
  index = true,
  gui = true,
  parent = true,
  direction = true,
  children_names = true,
  player_index = true,
  type = true,
  children = true,
  elem_type = true,
  column_count = true,
  tabs = true,
  valid = true
}

-- FIELDS

local roots = {}

-- HELPER FUNCTIONS

local function get_or_create_player_table(player_index)
  local players = global.__flib.gui.players
  local player_table = players[player_index]
  if player_table then
    return player_table
  else
    players[player_index] = {
      instances = {
        __nextindex = 1
      }
    }
    return players[player_index]
  end
end

-- BUILDING AND DIFFING

local function apply_view(self, parent, index, view)
  local children = parent.children
  local elem = children[index]

  -- destroy and recreate if the type changed
  if elem and view.type and view.type ~= elem.type then
    children[index].destroy()
    elem = nil
  end

  -- add a new element if the current one doesn't exist or was deleted
  if not elem then
    view.index = index
    elem = parent.add(view)
    view.index = nil
    elem.tags = {
      flib = {events = {}}
    }
  end

  -- iterate keys
  for key, value in pairs(view) do
    if not elem_read_only_keys[key] then
      local event_id = event_keys[key]
      if elem_style_keys[key] then
        elem.style[key] = value
      elseif elem_functions[key] then
        elem[key](table.unpack(value))
      elseif event_id then
        local elem_tags = elem.tags
        local event_tags = elem_tags.flib.events
        local value_type = type(value)
        if value_type == "table" and value.__removed then
          event_tags[event_id] = nil
        else
          event_tags[event_id] = {gui_index = self.gui_index, msg = value}
        end
        elem.tags = elem_tags
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

  --[[

  TABS LOGIC:
  - tabs are always shown in the order that they appear in the provided tabs array
  - if a content's type changes, then the following happens:
    - the corresponding tab will automactically disappear
    - current content is destroyed
    - remove_tab() is called for all subsequent tabs
    - add_tab() is called on the current tab and new content
    - add_tab() is called for all removed tabs
  - if a tab or a content is removed separately, then throw an error
    - only the actual tab-and-content table may be removed
  - if a tab-and-content is removed, simply call remove_tab() for that set and destroy the elements
  - if a tab-and-content is provided outside the currently stored tab-and-contents, add the elements and call add_tab()
  ]]

  -- update children
  elem_children = elem.children

  -- process tabs
  if elem.type == "tabbed-pane" then
    local elem_tabs = elem.tabs

    for tab_index, tab_and_content in pairs(view.tabs) do
      if tab_and_content.__removed then
        -- remove from visible
        local removed_tab_and_content = elem_tabs[tab_index]
        elem.remove_tab(removed_tab_and_content.tab)
        -- destroy elements
        removed_tab_and_content.tab.destroy()
        removed_tab_and_content.content.destroy()
      else
        local real_tab_and_content = elem_tabs[tab_index]
        if real_tab_and_content then
          local tab = real_tab_and_content.tab
          -- update tab if needed
          local tab_view = tab_and_content.tab
          if tab_view then
            -- we can safely assume that the tab's type will never change, since tabs are the only valid tabs...
            apply_view(self, elem, tab.get_index_in_parent(), tab_view)
          end

          -- update content if needed
          local content = real_tab_and_content.content
          local content_view = tab_and_content.content
          if content_view then
            local updated_content = apply_view(self, elem, content.get_index_in_parent(), content_view)
            -- if the content was destroyed and re-made
            if not content.valid then
              -- remove this and all subsequent tabs
              for i = tab_index, #elem_tabs do
                elem.remove_tab(elem_tabs[i].tab)
              end
              -- add new current tab
              elem.add_tab(tab, updated_content)
              -- re-add all subsequent tabs
              for i = tab_index + 1, #elem_tabs do
                local this_tab_and_content = elem_tabs[i]
                elem.add_tab(this_tab_and_content.tab, this_tab_and_content.content)
              end
              -- set selected tab index again
              local selected = elem.selected_tab_index
              elem.selected_tab_index = nil
              elem.selected_tab_index = selected
            end
          end
        else
          -- new tab
          local tab = apply_view(self, elem, nil, tab_and_content.tab)
          local content = apply_view(self, elem, nil, tab_and_content.content)
          elem.add_tab(tab, content)
        end
      end
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
- if the value of a handler message changes, and that message is a table, then don't diff the table - include all of it

]]

local function diff(old, new, flags)
  for key, value in pairs(new) do
    local old_value = old[key]
    if old_value and type(old_value) == "table" and type(value) == "table" then
      if old_value.type ~= value.type then
        old[key] = value
      else
        local is_handler = event_keys[key] and true or false
        local different = diff(old_value, value, {is_handler = is_handler, is_children = key == "children"})
        if is_handler and different then
          old[key] = value
        -- TODO find a more performant way to do this
        elseif is_handler or table_size(old_value) == 0 then
          old[key] = nil
        end
      end
    elseif old_value ~= value then
      if flags.is_handler then
        return true
      end
      old[key] = value
    elseif not flags.is_handler then
      old[key] = nil
    end
  end
  for key in pairs(old) do
    local new_value = new[key]
    if new_value == nil then
      old[key] = {__removed = true}
    end
  end
end

-- GUI "INSTANCE"

local GuiInstance = {}

-- update the state, generate a new view, diff it, and apply the results
function GuiInstance:update(msg, e)
  local Root = roots[self.gui_name]
  Root:update(self.state, msg, e)

  local new_view = Root:view(self.state)

  -- TODO
  -- the stored `last_view` will be modified and consumed to become the diff, in order to avoid deepcopying
  local last_view = self.last_view
  diff(last_view, new_view, {})
  apply_view(self, self.parent, self.root_child_index, last_view)

  -- save the new view as the last view for future diffing
  self.last_view = new_view
end

-- destroy the instance and clean up handlers
function GuiInstance:destroy()
  local player_table = get_or_create_player_table(self.player_index)
  local player_instances = player_table.instances

  self.root.destroy()

  player_instances[self.gui_index] = nil
end

-- GUI "ROOT"

local GuiRoot = {}

-- create an instance of this GUI
function GuiRoot:new(parent, ...)
  local player_index = parent.player_index or parent.player.index
  local player_table = get_or_create_player_table(player_index)
  local player_instances = player_table.instances

  local initial_state = self:init(player_index, ...)

  if type(initial_state) ~= "table" then
    error("State must be a table.")
  end

  local index = player_instances.__nextindex

  local initial_view = self:view(initial_state)

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

  player_instances[index] = instance
  player_instances.__nextindex = index + 1

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
    for key, Instance in pairs(player_table.instances) do
      if key ~= "__nextindex" then
        setmetatable(Instance, {__index = GuiInstance})
      end
    end
  end
end

-- TODO add migration function

function flib_gui.dispatch(event_data)
  local element = event_data.element
  if not element then return end

  local flib_tags = event_data.element.tags.flib
  if not flib_tags then return false end

  local event_info = flib_tags.events[tostring(event_data.name)]
  if not event_info then return false end

  local player_data = global.__flib.gui.players[event_data.player_index]
  if not player_data then return false end

  local Instance = player_data.instances[event_info.gui_index]
  if not Instance then return false end -- ? this should probably error

  Instance:update(event_info.msg, event_data)

  return true
end

function flib_gui.register_handlers()
  for _, event_id in pairs(event_keys) do
    script.on_event(tonumber(event_id), flib_gui.dispatch)
  end
end

--- Create a new GUI root.
--
-- This sets up the instance metatable for this GUI and adds the `create()` method to the root.
-- @tparam string name The name of the GUI. Must be unique.
-- @treturn table The newly created GUI root. Add your `init()`, `update()` and `view()` functions to this table
-- before returning it.
-- @usage
-- local my_gui = gui.new("my_gui")
function flib_gui.root(name)
  if roots[name] then
    error("Duplicate GUI name ["..name.."] - every GUI must have a unique name.")
  end

  local obj = {name = name}

  setmetatable(obj, {__index = GuiRoot})

  roots[name] = obj

  return obj
end

return flib_gui