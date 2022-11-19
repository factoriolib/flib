local position = require("__flib__/position")

--- Utilities for manipulating bounding boxes. All functions support both the shorthand and explicit syntaxes and will
--- preserve the syntax that was passed in. All functions return new objects.
local flib_bounding_box = {}

--- Expand the `BoundingBox` to its outer tile edges.
--- @param box BoundingBox
--- @return BoundingBox
function flib_bounding_box.ceil(box)
  local e_box = flib_bounding_box.ensure_explicit(box)
  if box.left_top then
    return {
      left_top = { x = math.floor(e_box.left_top.x), y = math.floor(e_box.left_top.y) },
      right_bottom = { x = math.ceil(e_box.right_bottom.x), y = math.ceil(e_box.right_bottom.y) },
    }
  else
    return {
      { math.floor(e_box.left_top.x), math.floor(e_box.left_top.y) },
      { math.ceil(e_box.right_bottom.x), math.ceil(e_box.right_bottom.y) },
    }
  end
end

--- Check if the first `BoundingBox` contains the second `BoundingBox`.
--- @param box1 BoundingBox
--- @param box2 BoundingBox
--- @return boolean
function flib_bounding_box.contains_box(box1, box2)
  local e_box1 = flib_bounding_box.ensure_explicit(box1)
  local e_box2 = flib_bounding_box.ensure_explicit(box2)

  return e_box1.left_top.x <= e_box2.left_top.x
    and e_box1.left_top.y <= e_box2.left_top.y
    and e_box1.right_bottom.x >= e_box2.right_bottom.x
    and e_box1.right_bottom.y >= e_box2.right_bottom.y
end

--- Ensure that the passed `BoundingBox` is in explicit form, or convert if it is not.
--- @param box BoundingBox
--- @return BoundingBox
function flib_bounding_box.ensure_explicit(box)
  if box.left_top and box.right_bottom then
    return {
      left_top = position.ensure_xy(box.left_top),
      right_bottom = position.ensure_xy(box.right_bottom),
    }
  else
    return {
      left_top = position.ensure_xy(box[1]),
      right_bottom = position.ensure_xy(box[2]),
    }
  end
end

--- Ensure that the passed `BoundingBox` is in shorthand form, or convert if it is not.
--- @param box BoundingBox
--- @return BoundingBox
function flib_bounding_box.ensure_short(box)
  if box.left_top and box.right_bottom then
    return {
      position.ensure_short(box.left_top),
      position.ensure_short(box.right_bottom),
    }
  else
    return {
      position.ensure_short(box[1]),
      position.ensure_short(box[2]),
    }
  end
end

--- Shrink the `BoundingBox` to its innser tile edges.
--- @param box BoundingBox
--- @return BoundingBox
function flib_bounding_box.floor(box)
  local e_box = flib_bounding_box.ensure_explicit(box)
  if box.left_top then
    return {
      left_top = { x = math.ceil(e_box.left_top.x), y = math.ceil(e_box.left_top.y) },
      right_bottom = { x = math.floor(e_box.right_bottom.x), y = math.floor(e_box.right_bottom.y) },
    }
  else
    return {
      { math.ceil(e_box.left_top.x), math.ceil(e_box.left_top.y) },
      { math.floor(e_box.right_bottom.x), math.floor(e_box.right_bottom.y) },
    }
  end
end

--- Calculate the centerpoint of the `BoundingBox`. The return value matches the form of the area.
--- @param box BoundingBox
--- @return MapPosition
function flib_bounding_box.get_center(box)
  if box.left_top and box.right_bottom then
    return {
      x = box.left_top.x + (math.abs(box.right_bottom.x - box.left_top.x) / 2),
      y = box.left_top.y + (math.abs(box.right_bottom.y - box.left_top.y) / 2),
    }
  else
    return {
      box[1][1] + (math.abs(box[2][1] - box[1][1]) / 2),
      box[1][2] + (math.abs(box[2][2] - box[1][2]) / 2),
    }
  end
end

--- Calculate the height of the `BoundingBox`.
--- @param box BoundingBox
--- @return number
function flib_bounding_box.get_height(box)
  if box.left_top and box.right_bottom then
    return box.left_top.y + (math.abs(box.right_bottom.y - box.left_top.y) / 2)
  else
    return box[1][2] + (math.abs(box[2][2] - box[1][2]) / 2)
  end
end

--- Calculate the width of the `BoundingBox`.
--- @param box BoundingBox
--- @return number
function flib_bounding_box.get_width(box)
  if box.left_top and box.right_bottom then
    return box.left_top.x + (math.abs(box.right_bottom.x - box.left_top.x) / 2)
  else
    return box[1][1] + (math.abs(box[2][1] - box[1][1]) / 2)
  end
end

--- Re-center the `BoundingBox` on the given `MapPosition`.
--- @param box BoundingBox
--- @param pos MapPosition
--- @return BoundingBox
function flib_bounding_box.recenter_on(box, pos)
  local height = flib_bounding_box.get_height(box)
  local width = flib_bounding_box.get_width(box)

  local pos_x = pos.x or pos[1]
  local pos_y = pos.y or pos[2]

  if box.left_top then
    return {
      left_top = { x = pos_x - (width / 2), y = pos_y - (width / 2) },
      right_bottom = { x = pos_x + (height / 2), y = pos_y + (height / 2) },
    }
  else
    return {
      { pos_x - (width / 2), pos_y - (width / 2) },
      { pos_x + (height / 2), pos_y + (height / 2) },
    }
  end
end

return flib_bounding_box
