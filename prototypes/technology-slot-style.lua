local styles = data.raw["gui-style"]["default"]

--- @param name string
--- @param y number
--- @param level_color Color
--- @param level_range_color Color
local function build_technology_slot(name, y, level_color, level_range_color)
  styles["flib_technology_slot_" .. name] = {
    type = "button_style",
    default_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 0, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    hovered_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 144, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    clicked_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 144, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    selected_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 288, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    selected_hovered_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 432, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    selected_clicked_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 432, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    padding = 0,
    size = { 72, 100 },
    left_click_sound = { filename = "__core__/sound/gui-square-button-large.ogg", volume = 1 },
  }

  styles["flib_technology_slot_" .. name .. "_multilevel"] = {
    type = "button_style",
    default_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 576, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    hovered_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 720, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    clicked_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 720, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    selected_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 864, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    selected_hovered_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 1008, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    selected_clicked_graphical_set = {
      base = {
        filename = "__flib__/graphics/technology-slots.png",
        position = { 1008, y },
        size = { 144, 200 },
      },
      shadow = default_shadow,
    },
    padding = 0,
    size = { 72, 100 },
    left_click_sound = { filename = "__core__/sound/gui-square-button-large.ogg", volume = 1 },
  }

  styles["flib_technology_slot_level_label_" .. name] = {
    type = "label_style",
    font = "technology-slot-level-font",
    font_color = level_color,
    top_padding = 66,
    width = 26,
    horizontal_align = "center",
  }

  styles["flib_technology_slot_level_range_label_" .. name] = {
    type = "label_style",
    font = "technology-slot-level-font",
    font_color = level_range_color,
    top_padding = 66,
    right_padding = 4,
    width = 72,
    horizontal_align = "right",
  }
end

build_technology_slot("available", 0, { 77, 71, 48 }, { 255, 241, 183 })
build_technology_slot("conditionally_available", 200, { 95, 68, 32 }, { 255, 234, 206 })
build_technology_slot("not_available", 400, { 116, 34, 32 }, { 255, 214, 213 })
build_technology_slot("researched", 600, { 0, 84, 5 }, { 165, 255, 171 })
build_technology_slot("disabled", 800, { 132, 132, 132 }, { 132, 132, 132 })

styles.flib_technology_slot_sprite_flow = {
  type = "horizontal_flow_style",
  width = 72,
  height = 68,
  vertical_align = "center",
  horizontal_align = "center",
}

styles.flib_technology_slot_sprite = {
  type = "image_style",
  size = 64,
  stretch_image_to_widget_size = true,
}

styles.flib_technology_slot_ingredients_flow = {
  type = "horizontal_flow_style",
  top_padding = 82,
  left_padding = 2,
}

styles.flib_technology_slot_ingredient = {
  type = "image_style",
  size = 16,
  stretch_image_to_widget_size = true,
}

styles.flib_technology_slot_progressbar = {
  type = "progressbar_style",
  bar = { position = { 305, 39 }, corner_size = 4 },
  bar_shadow = {
    base = { position = { 296, 39 }, corner_size = 4 },
    shadow = {
      left = { position = { 456, 152 }, size = { 16, 1 } },
      center = { position = { 472, 152 }, size = { 1, 1 } },
      right = { position = { 473, 152 }, size = { 16, 1 } },
    },
  },
  bar_width = 4,
  color = { g = 1 },
  width = 72,
}
