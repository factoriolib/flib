-- SLOT BUTTON STYLES

local styles = data.raw["gui-style"].default

local slot_tileset = "__flib__/graphics/slots.png"

local function gen_slot(y, start_x, is_selected)
  local default_x = is_selected and (start_x + 80) or start_x
  return {
    type = "button_style",
    parent = "slot_button",
    size = 40,
    default_graphical_set = {
      base = {border=4, position={default_x , y}, size=80, filename=slot_tileset},
    },
    hovered_graphical_set = {
      base = {border=4, position={(start_x + 80), y}, size=80, filename=slot_tileset},
    },
    clicked_graphical_set = {
      base = {border=4, position={(start_x + 160), y}, size=80, filename=slot_tileset},
    },
    disabled_graphical_set = { -- identical to default graphical set
      base = {border=4, position={default_x, y}, size=80, filename=slot_tileset},
    },
    left_click_sound = {{filename="__core__/sound/gui-inventory-slot-button.ogg", volume=0.6}}
  }
end

local function gen_slot_button(y, start_x, is_selected, glow)
  local default_x = is_selected and (start_x + 80) or start_x
  return {
    type = "button_style",
    parent = "slot_button",
    size = 40,
    default_graphical_set = {
      base = {border=4, position={default_x , y}, size=80, filename=slot_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    hovered_graphical_set = {
      base = {border=4, position={(start_x + 80), y}, size=80, filename=slot_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
      glow = offset_by_2_rounded_corners_glow(glow)
    },
    clicked_graphical_set = {
      base = {border=4, position={(start_x + 160), y}, size=80, filename=slot_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    disabled_graphical_set = { -- identical to default graphical set
      base = {border=4, position={default_x, y}, size=80, filename=slot_tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    left_click_sound = {{filename="__core__/sound/gui-inventory-slot-button.ogg", volume=0.6}}
  }
end

local function gen_standalone_slot_button(y, start_x, is_selected)
  local default_x = is_selected and (start_x + 80) or start_x
  return {
    type = "button_style",
    parent = "slot_button",
    size = 40,
    default_graphical_set = {
      base = {border=4, position={default_x , y}, size=80, filename=slot_tileset},
      shadow = offset_by_4_rounded_corners_subpanel_inset
    },
    hovered_graphical_set = {
      base = {border=4, position={(start_x + 80), y}, size=80, filename=slot_tileset},
      shadow = offset_by_4_rounded_corners_subpanel_inset
    },
    clicked_graphical_set = {
      base = {border=4, position={(start_x + 160), y}, size=80, filename=slot_tileset},
      shadow = offset_by_4_rounded_corners_subpanel_inset
    },
    disabled_graphical_set = { -- identical to default graphical set
      base = {border=4, position={default_x, y}, size=80, filename=slot_tileset},
      shadow = offset_by_4_rounded_corners_subpanel_inset
    },
    left_click_sound = {{filename="__core__/sound/gui-inventory-slot-button.ogg", volume=0.6}}
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

for _, data in ipairs(slot_data) do
  styles["flib_slot_"..data.name] = gen_slot(data.y, 0)
  styles["flib_selected_slot_"..data.name] = gen_slot(data.y, 0, true)
  styles["flib_slot_button_"..data.name] = gen_slot_button(data.y, 240, false, data.glow)
  styles["flib_selected_slot_button_"..data.name] = gen_slot_button(data.y, 240, true, data.glow)
  styles["flib_standalone_slot_button_"..data.name] = gen_standalone_slot_button(data.y, 240, false)
  styles["flib_selected_standalone_slot_button_"..data.name] = gen_standalone_slot_button(data.y, 240, true)
end