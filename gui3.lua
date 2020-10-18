--- A GUI library inspired by Elm and Seed-RS.
-- @module gui
-- @alias flib_gui
local flib_gui = {}

local table = require("__flib__.table")

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
  set_slider_minimum_maximum = true,
  set_slider_value_step = true,
  set_slider_discrete_slider = true,
  set_slider_discrete_values = true,
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
  scroll_to_item = true,
  bring_to_front = true
}

local elem_style_keys = {
  -- gui = {read_only = true},
  -- name = {read_only = true},
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
  -- column_alignments = {read_only = true},
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

local elem_keys = {
  index = {read_only = true},
  gui = {read_only = true},
  parent = {read_only = true},
  name = {read_only = true},
  caption = {},
  value = {},
  direction = {read_only = true},
  style = {},
  visible = {},
  text = {},
  children_names = {read_only = true},
  state = {},
  player_index = {read_only = true},
  sprite = {},
  resize_to_sprite = {},
  hovered_sprite = {},
  clicked_sprite = {},
  tooltip = {},
  horizontal_scroll_policy = {},
  vertical_scroll_policy = {},
  type = {read_only = true},
  -- children = {read_only = true},
  items = {},
  selected_index = {},
  number = {},
  show_percent_for_small_numbers = {},
  location = {},
  auto_center = {},
  badge_text = {},
  position = {},
  surface_index = {},
  zoom = {},
  minimap_player_index = {},
  force = {},
  elem_type = {read_only = true},
  elem_value = {},
  elem_filters = {},
  selectable = {},
  word_wrap = {},
  read_only = {},
  enabled = {},
  ignored_by_interaction = {},
  locked = {},
  draw_vertical_lines = {},
  draw_horizontal_lines = {},
  draw_horizontal_line_after_headers = {},
  column_count = {read_only = true},
  vertical_centering = {},
  slider_value = {},
  mouse_button_filter = {},
  numeric = {},
  allow_decimal = {},
  allow_negative = {},
  is_password = {},
  lose_focus_on_confirm = {},
  clear_and_focus_on_right_click = {},
  drag_target = {},
  selected_tab_index = {},
  -- tabs = {read_only = true},
  entity = {},
  switch_state = {},
  allow_none_state = {},
  left_label_caption = {},
  left_label_tooltip = {},
  right_label_caption = {},
  right_label_tooltip = {},
  tags = {}
}

-- FIELDS

local roots = {}

flib_gui.orders = {
  destroy = 1,
  skip_view = 2
}

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

    -- if the instance's base elem doesn't exist, this is it
    if not self.base_elem or not self.base_elem.valid then
      self.base_elem = elem
    end
  end

  -- iterate keys
  for key, value in pairs(view) do
    local key_data = elem_keys[key]
    local event_id = event_keys[key]
    if elem_style_keys[key] then
      elem.style[key] = value
    elseif elem_functions[key] then
      if type(value) == "table" then
        if not value.__removed then
          elem[key](table.unpack(value))
        end
      elseif value then
        elem[key]()
      end
    elseif event_id then
      local elem_tags = elem.tags
      local event_tags = elem_tags.flib.events
      local value_type = type(value)
      if value_type == "table" and value.__removed then
        event_tags[event_id] = nil
      else
        event_tags[event_id] = {index = self.index, msg = value}
      end
      elem.tags = elem_tags
    elseif key == "ref" then
      local elem_tags = elem.tags
      local existing_ref = elem_tags.flib.ref
      if existing_ref then
        self.refs[existing_ref] = nil
      end
      self.refs[value] = elem
    elseif key_data and not key_data.read_only then
      if type(value) == "table" and not value.__self and value.__removed then
        elem[key] = nil
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
  if elem.type == "tabbed-pane" and view.tabs then
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
          -- TODO revisit this, it might be broken on some edge-cases
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
- if a read-only key changes, delete and re-create the element from scratch, inserting it into its old position
- if the value of a handler message changes, and that message is a table, then don't diff the table - include all of it
]]

local function diff(old, new)
  for key, value in pairs(new) do
    local old_value = old[key]
    if
      old_value
      and type(old_value) == "table"
      and not old_value.__self
      and type(value) == "table"
      and not value.__self
    then
      if elem_keys[key] or elem_style_keys[key] or elem_functions[key] or event_keys[key] then
        -- compare the two tables without modifying them
        if table.deep_compare(old_value, value) then
          old[key] = nil
        else
          old[key] = value
        end
      else
        if old_value.type ~= value.type then
          old[key] = value
        else
          diff(old_value, value)
          if not next(old_value) then
            old[key] = nil
          end
        end
      end
    elseif old_value ~= value then
      old[key] = value
    else
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
function GuiInstance:dispatch(msg, e)
  local root = roots[self.root_name]
  if not root then error("Could not find GUI root ["..self.root_name.."]") end

  local orders = root.update(self.state, msg, e, self.refs) or {}

  for _, order in ipairs(orders) do
    if order == flib_gui.orders.destroy then
      self:destroy()
      return
    elseif order == flib_gui.orders.skip_view then
      return
    end
  end

  local new_view = root.view(self.state)

  -- the stored `last_view` will be modified and consumed to become the diff, in order to avoid deepcopying
  local last_view = self.last_view
  diff(last_view, new_view, {})
  apply_view(self, self.parent, self.base_elem.get_index_in_parent(), last_view)

  -- save the new view as the last view for future diffing
  self.last_view = new_view
end

-- destroy the instance and clean up handlers
function GuiInstance:destroy()
  local player_table = get_or_create_player_table(self.player_index)
  local player_instances = player_table.instances

  self.base_elem.destroy()

  player_instances[self.index] = nil
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

  local Instance = player_data.instances[event_info.index]
  if not Instance then return false end -- ? this should probably error

  Instance:dispatch(event_info.msg, event_data)

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

  local root = {name = name}

  roots[name] = root

  return root
end

function flib_gui.new(root, parent, ...)
  local player_index = parent.player_index or parent.player.index
  local player_table = get_or_create_player_table(player_index)
  local player_instances = player_table.instances

  -- create instance class
  local index = player_instances.__nextindex
  local Instance = setmetatable(
    {
      index = index,
      parent = parent,
      player_index = player_index,
      refs = {},
      root_name = root.name,
    },
    {__index = GuiInstance}
  )
  -- save instance class
  player_instances[index] = Instance
  player_instances.__nextindex = index + 1

  -- generate, check, and save initial state
  local initial_state = root.init(player_index, ...)
  if type(initial_state) ~= "table" then
    error("State must be a table.")
  end
  Instance.state = initial_state

  -- create the GUI and save the base element to be destroyed later
  -- we don't need to do any diffing here since it is the first time it's being made
  Instance.last_view = root.view(initial_state)
  apply_view(Instance, parent, #parent.children + 1, Instance.last_view)

  -- one-time setup
  if root.setup then
    root.setup(Instance.refs, player_index, ...)
  end

  return Instance
end

function flib_gui.component()
  return setmetatable({}, {
    __call = function(self, ...) return self.view(...) end
  })
end

return flib_gui