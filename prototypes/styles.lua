-- SLOT BUTTON STYLES

local slot_tileset = "__flib__/graphics/slots.png"
local styles = data.raw["gui-style"].default

local function gen_slot(x, y, is_selected)
  local default_offset = default_offset or 0
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
    },
  }
end

local function gen_slot_button(x, y, default_offset, glow)
  local default_offset = default_offset or 0
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
    },
  }
end

local function gen_standalone_slot_button(x, y, default_offset)
  local default_offset = default_offset or 0
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
    },
  }
end

local slot_data = {
  {name="default", y=0, glow=default_glow_color},
  {name="red", y=80, glow={230, 135, 135}},
  {name="yellow", y=160, glow={230, 218, 135}},
  {name="green", y=240, glow={153, 230, 135}},
  {name="cyan", y=320, glow={135, 230, 230}},
  {name="blue", y=400, glow={135, 186, 230}},
  {name="purple", y=480, glow={188, 135, 230}},
  {name="pink", y=560, glow={230, 135, 230}}
}

for _, data in pairs(slot_data) do
  styles["flib_slot_"..data.name] = gen_slot(0, data.y)
  styles["flib_selected_slot_"..data.name] = gen_slot(0, data.y, 80)
  styles["flib_slot_button_"..data.name] = gen_slot_button(240, data.y, 0, data.glow)
  styles["flib_selected_slot_button_"..data.name] = gen_slot_button(240, data.y, 80, data.glow)
  styles["flib_standalone_slot_button_"..data.name] = gen_standalone_slot_button(240, data.y)
  styles["flib_selected_standalone_slot_button_"..data.name] = gen_standalone_slot_button(240, data.y, 80)
end