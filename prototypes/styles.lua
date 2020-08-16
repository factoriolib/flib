local styles = data.raw["gui-style"].default

-- SLOT BUTTON STYLES

local slot_tileset = "__flib__/graphics/slots.png"

local function gen_slot(x, y, default_offset)
  default_offset = default_offset or 0
  return {
    type = "button_style",
    parent = "slot",
    size = 40,
    default_graphical_set = {
      base = {border=4, position={x + default_offset , y}, size=80, filename=slot_tileset},
    },
    hovered_graphical_set = {
      base = {border=4, position={x + 80, y}, size=80, filename=slot_tileset},
    },
    clicked_graphical_set = {
      base = {border=4, position={x + 160, y}, size=80, filename=slot_tileset},
    },
    disabled_graphical_set = { -- identical to default graphical set
      base = {border=4, position={x + default_offset, y}, size=80, filename=slot_tileset},
    }
  }
end

local function gen_slot_button(x, y, default_offset, glow)
  default_offset = default_offset or 0
  return {
    type = "button_style",
    parent = "slot_button",
    size = 40,
    default_graphical_set = {
      base = {border=4, position={x + default_offset , y}, size=80, filename=slot_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    hovered_graphical_set = {
      base = {border=4, position={x + 80, y}, size=80, filename=slot_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
      glow = offset_by_2_rounded_corners_glow(glow)
    },
    clicked_graphical_set = {
      base = {border=4, position={x + 160, y}, size=80, filename=slot_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    disabled_graphical_set = { -- identical to default graphical set
      base = {border=4, position={x + default_offset, y}, size=80, filename=slot_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    }
  }
end

local function gen_standalone_slot_button(x, y, default_offset)
  default_offset = default_offset or 0
  return {
    type = "button_style",
    parent = "slot_button",
    size = 40,
    default_graphical_set = {
      base = {border=4, position={x + default_offset , y}, size=80, filename=slot_tileset},
      shadow = offset_by_4_rounded_corners_subpanel_inset
    },
    hovered_graphical_set = {
      base = {border=4, position={x + 80, y}, size=80, filename=slot_tileset},
      shadow = offset_by_4_rounded_corners_subpanel_inset
    },
    clicked_graphical_set = {
      base = {border=4, position={x + 160, y}, size=80, filename=slot_tileset},
      shadow = offset_by_4_rounded_corners_subpanel_inset
    },
    disabled_graphical_set = { -- identical to default graphical set
      base = {border=4, position={x + default_offset, y}, size=80, filename=slot_tileset},
      shadow = offset_by_4_rounded_corners_subpanel_inset
    }
  }
end

local slot_data = {
  {name="default", y=0, glow=default_glow_color},
  {name="grey", y=80, glow=default_glow_color},
  {name="red", y=160, glow={230, 135, 135}},
  {name="orange", y=240, glow={216, 169, 122}},
  {name="yellow", y=320, glow={230, 218, 135}},
  {name="green", y=400, glow={153, 230, 135}},
  {name="cyan", y=480, glow={135, 230, 230}},
  {name="blue", y=560, glow={135, 186, 230}},
  {name="purple", y=640, glow={188, 135, 230}},
  {name="pink", y=720, glow={230, 135, 230}}
}

for _, data in pairs(slot_data) do
  styles["flib_slot_"..data.name] = gen_slot(0, data.y)
  styles["flib_selected_slot_"..data.name] = gen_slot(0, data.y, 80)
  styles["flib_slot_button_"..data.name] = gen_slot_button(240, data.y, 0, data.glow)
  styles["flib_selected_slot_button_"..data.name] = gen_slot_button(240, data.y, 80, data.glow)
  styles["flib_standalone_slot_button_"..data.name] = gen_standalone_slot_button(240, data.y)
  styles["flib_selected_standalone_slot_button_"..data.name] = gen_standalone_slot_button(240, data.y, 80)
end

-- BUTTON STYLES

styles.flib_selected_frame_action_button = {
  type = "button_style",
  parent = "frame_action_button",
  default_graphical_set = {
    base = {position = {272, 169}, corner_size = 8},
    shadow = {position = {440, 24}, corner_size = 8, draw_type = "outer"}
  },
  hovered_graphical_set = {
    base = {position = {369, 17}, corner_size = 8},
    shadow = default_dirt
  },
  clicked_graphical_set = {
    base = {position = {352, 17}, corner_size = 8},
    shadow = default_dirt
  }
}

local btn = styles.button

styles.flib_selected_tool_button = {
  type = "button_style",
  parent = "tool_button",
  default_font_color = btn.selected_font_color,
  default_graphical_set = btn.selected_graphical_set,
  hovered_font_color = btn.selected_hovered_font_color,
  hovered_graphical_set = btn.selected_hovered_graphical_set,
  clicked_font_color = btn.selected_clicked_font_color,
  clicked_graphical_set = btn.selected_clicked_graphical_set
}

-- EMPTY-WIDGET STYLES

styles.flib_dialog_footer_drag_handle = {
  type = "empty_widget_style",
  parent = "draggable_space",
  height = 32,
  horizontally_stretchable = "on"
}

styles.flib_dialog_titlebar_drag_handle = {
  type = "empty_widget_style",
  parent = "flib_titlebar_drag_handle",
  right_margin = 0
}

styles.flib_horizontal_pusher = {
  type = "empty_widget_style",
  horizontally_stretchable = "on"
}

styles.flib_titlebar_drag_handle = {
  type = "empty_widget_style",
  parent = "draggable_space",
  left_margin = 4,
  right_margin = 4,
  height = 24,
  horizontally_stretchable = "on"
}

styles.flib_vertical_pusher = {
  type = "empty_widget_style",
  vertically_stretchable = "on"
}

-- SCROLL-PANE STYLES

styles.flib_naked_scroll_pane = {
  type = "scroll_pane_style",
  extra_padding_when_activated = 0,
  padding = 0,
  vertically_stretchable = "on",
  graphical_set = {
    shadow = default_inner_shadow
  },
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    padding = 12
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    padding = 12
  }
}

styles.flib_naked_scroll_pane_under_tabs = {
  type = "scroll_pane_style",
  parent = "flib_naked_scroll_pane",
  graphical_set = {
    base = {
      top = {position = {93, 0}, size = {1, 8}},
      draw_type = "outer"
    },
    shadow = default_inner_shadow
  }
}

styles.flib_naked_scroll_pane_no_padding = {
  type = "scroll_pane_style",
  extra_padding_when_activated = 0,
  padding = 0,
  graphical_set = {
    shadow = default_inner_shadow
  }
}