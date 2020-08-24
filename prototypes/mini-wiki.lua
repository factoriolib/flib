-- SHORTCUT

local data_util = require("__flib__.data_util")

data:extend{
  {
    type = "custom-input",
    name = "flib-toggle-miniwiki",
    key_sequence = "I",
    action = "lua"
  },
  {
    type = "shortcut",
    name = "flib-toggle-miniwiki",
    action = "lua",
    icon = data_util.build_sprite(nil, {0,0}, "__flib__/graphics/miniwiki-shortcut.png", 32, 2),
    small_icon = data_util.build_sprite(nil, {0,32}, "__flib__/graphics/miniwiki-shortcut.png", 24, 2),
    disabled_icon = data_util.build_sprite(nil, {48,0}, "__flib__/graphics/miniwiki-shortcut.png", 32, 2),
    disabled_small_icon = data_util.build_sprite(nil, {36,32}, "__flib__/graphics/miniwiki-shortcut.png", 24, 2),
    toggleable = true,
    associated_control_input = "flib-toggle-miniwiki"
  }
}

-- STYLES

local styles = data.raw["gui-style"]["default"]

styles.flib_mw_pages_scroll_pane = {
  type = "scroll_pane_style",
  parent = "list_box_scroll_pane",
  vertically_stretchable = "on",
  graphical_set = {
    shadow = default_inner_shadow
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0,
    horizontally_stretchable = "on"
  }
}

styles.flib_mw_list_box_item = {
  type = "button_style",
  parent = "list_box_item",
  left_padding = 4,
  right_padding = 4,
  horizontally_squashable = "on",
  horizontally_stretchable = "on",
  disabled_graphical_set = styles.button.selected_graphical_set,
  disabled_font_color = styles.button.selected_font_color
}