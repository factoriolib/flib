-- TODO: Using `self` makes the language server treat `flib_area` as a BoundingBox...

--- Functions for manipulating areas.
---
--- All functions in this module, with the exception of `area.to_shorthand()`, will ensure that the all passed areas have `left_top` and `right_bottom` keys.
---
--- All functions in this module will modify the area in-place as well as return it, to provide maximum flexibility.
---
--- All constructor functions in this module will apply a metatable allowing module methods to be called directly on the area objects (see `area.load()`).
---
local flib_area = {}

--- Expand an area to its outer tile edges.
--- @param self BoundingBox
function flib_area.ceil(self)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end
  self.left_top = {
    x = math.floor(self.left_top.x),
    y = math.floor(self.left_top.y),
  }
  self.right_bottom = {
    x = math.ceil(self.right_bottom.x),
    y = math.ceil(self.right_bottom.y),
  }

  return self
end

--- Calculate the centerpoint of the area.
--- @param self BoundingBox
--- @return Position center_point
function flib_area.center(self)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end
  return {
    x = self.left_top.x + (flib_area.width(self) / 2),
    y = self.left_top.y + (flib_area.height(self) / 2),
  }
end

--- Re-center the area on the given position.
--- @param self BoundingBox
--- @param center_point Position
--- @return BoundingBox self
function flib_area.center_on(self, center_point)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  local height = flib_area.height(self)
  local width = flib_area.width(self)

  self.left_top = {
    x = center_point.x - (width / 2),
    y = center_point.y - (height / 2),
  }
  self.right_bottom = {
    x = center_point.x + (width / 2),
    y = center_point.y + (height / 2),
  }

  return self
end

--- Check if the area contains the other area.
--- @param self BoundingBox
--- @param other_area BoundingBox
--- @return boolean
function flib_area.contains_area(self, other_area)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  return (
      self.left_top.x <= other_area.left_top.x
      and self.left_top.y <= other_area.left_top.y
      and self.right_bottom.x >= other_area.right_bottom.x
      and self.right_bottom.y >= other_area.right_bottom.y
    )
end

--- Check if the area contains the given position.
--- @param self BoundingBox
--- @param position Position
--- @return boolean
function flib_area.contains_position(self, position)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  return (
      self.left_top.x <= position.x
      and self.right_bottom.x >= position.x
      and self.left_top.y <= position.y
      and self.right_bottom.y >= position.y
    )
end

--- Add left_bottom and right_top keys to the area.
---
--- These keys will not be updated when you modify the area, so the recommended usage is to call this function whenever you need to read the extra keys.
--- @param self BoundingBox
--- @return BoundingBox
function flib_area.corners(self)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  self.left_bottom = {
    x = self.left_top.x,
    y = self.right_bottom.y,
  }
  self.right_top = {
    x = self.right_bottom.x,
    y = self.left_top.y,
  }

  return self
end

--- Find the distance between a position and the nearest edge of the area.
--- @param self BoundingBox
--- @param position Position
--- @return number
function flib_area.distance_to_nearest_edge(self, position)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  local x_distance = math.min(math.abs(self.left_top.x - position.x), math.abs(self.right_bottom.x - position.x))
  local y_distance = math.min(math.abs(self.left_top.y - position.y), math.abs(self.right_bottom.y - position.y))

  return math.min(x_distance, y_distance)
end

--- Expand the area by the given amount.
--- @param self BoundingBox
--- @param delta number
--- @return BoundingBox
function flib_area.expand(self, delta)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  self.left_top.x = self.left_top.x - delta
  self.right_bottom.x = self.right_bottom.x + delta
  self.left_top.y = self.left_top.y - delta
  self.right_bottom.y = self.right_bottom.y + delta

  return self
end

--- Expand the area to contain the other area.
--- @param self BoundingBox
--- @param other_area BoundingBox
--- @return BoundingBox
function flib_area.expand_to_contain_area(self, other_area)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  self.left_top = {
    x = self.left_top.x < other_area.left_top.x and self.left_top.x or other_area.left_top.x,
    y = self.left_top.y < other_area.left_top.y and self.left_top.y or other_area.left_top.y,
  }
  self.right_bottom = {
    x = self.right_bottom.x > other_area.right_bottom.x and self.right_bottom.x or other_area.right_bottom.x,
    y = self.right_bottom.y > other_area.right_bottom.y and self.right_bottom.y or other_area.right_bottom.y,
  }

  return self
end

--- Expand the area to contain the given position.
--- @param self BoundingBox
--- @param position Position
--- @return BoundingBox
function flib_area.expand_to_contain_position(self, position)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  self.left_top = {
    x = self.left_top.x < position.x and self.left_top.x or position.x,
    y = self.left_top.y < position.y and self.left_top.y or position.y,
  }
  self.right_bottom = {
    x = self.right_bottom.x > position.x and self.right_bottom.x or position.x,
    y = self.right_bottom.y > position.y and self.right_bottom.y or position.y,
  }

  return self
end

--- Shrink the area to its inner tile edges.
--- @param self BoundingBox
--- @return BoundingBox
function flib_area.floor(self)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  self.left_top = {
    x = math.ceil(self.left_top.x),
    y = math.ceil(self.left_top.y),
  }
  self.right_bottom = {
    x = math.floor(self.right_bottom.x),
    y = math.floor(self.right_bottom.y),
  }

  return self
end

--- Create an area from dimensions and a centerpoint.
--- @param dimensions DisplayResolution
--- @param center? Position
--- @return BoundingBox
function flib_area.from_dimensions(dimensions, center)
  center = center or { x = 0, y = 0 }
  local self = {
    left_top = {
      x = center.x - (dimensions.width / 2),
      y = center.y - (dimensions.height / 2),
    },
    right_bottom = {
      x = center.x + (dimensions.width / 2),
      y = center.y + (dimensions.height / 2),
    },
  }
  flib_area.load(self)
  return self
end

--- Create a 1x1 tile area from the given position.
--- @param position Position
--- @param snap boolean? If true, snap the created area to the tile edges the position is contained in.
function flib_area.from_position(position, snap)
  local self
  if snap then
    local floored_position = { x = math.floor(position.x), y = math.floor(position.y) }
    self = {
      left_top = { x = floored_position.x, y = floored_position.y },
      right_bottom = { x = floored_position.x + 1, y = floored_position.y + 1 },
    }
  else
    self = {
      left_top = { x = position.x - 0.5, y = position.y - 0.5 },
      right_bottom = { x = position.x + 0.5, y = position.y + 0.5 },
    }
  end

  if self then
    flib_area.load(self)
    return self
  end
end

--- Create a proper area from a shorthanded area.
---
--- A "shorthand" area is an area without the `left_top` and `right_bottom` keys, which is sometimes used by the game in the data stage.
---
--- This function will automatically be called when using any other non-constructor function in this module.
--- @param area BoundingBox
--- @return BoundingBox
function flib_area.from_shorthand(area)
  local self = {
    left_top = { x = area[1][1], y = area[1][2] },
    right_bottom = { x = area[2][1], y = area[2][2] },
  }
  flib_area.load(self)
  return self
end

--- Calculate the height of the area.
--- @param self BoundingBox
--- @return number
function flib_area.height(self)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  return math.abs(self.right_bottom.y - self.left_top.y)
end

--- Create an iterator of positions in the area from the left-top to the right-bottom, incrementing by `step`.
---
--- The iterator function, when called, will return a `Position` that is within the area.
---
--- # Examples
---
--- ```lua
--- local MyArea = area.from_dimensions({ height = 10, width = 10 }, { x = 0, y = 0 })
--- for position in MyArea:iterate() do
---   log(serpent.line(position))
--- end
--- ```
--- @param self BoundingBox
--- @param step number? The distance between each returned position (default: `1`).
--- @return fun(): Position
function flib_area.iterate(self, step)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  step = step or 1

  local x = self.left_top.x
  local y = self.left_top.y
  local max_x = self.right_bottom.x
  local max_y = self.right_bottom.y
  local first = true

  return function()
    if first then
      first = false
      return { x = x, y = y }
    end

    local new_x = x + step
    if x < max_x and new_x < max_x then
      x = new_x
    else
      local new_y = y + step
      if y < max_y and new_y < max_y then
        x = self.left_top.x
        y = new_y
      else
        return nil
      end
    end

    return { x = x, y = y }
  end
end

--- Create an area object from a plain area.
---
--- Doing this allows one to use area methods directly on an area "object" via the `:` operator. The area will be passed
--- in as `self` to each function automatically.
---
--- Metatables do not persist across save/load, so when using area objects, this function must be called on them whenever
--- they are retrieved from `global` or during `on_load`.
---
--- # Examples
---
--- ```lua
--- -- Create the area object
--- local MyArea = area.load(event_data.area)
---
--- -- Use module methods directly on the object
--- log("Center: " .. MyArea:center())
--- for position in MyArea:iterate(0.5) do
---   log(serpent.line(position))
--- end
--- ```
--- @param area BoundingBox
--- @return BoundingBox
function flib_area.load(area)
  local area = area
  if not area.left_top then
    area = flib_area.from_shorthand(area)
  end
  return setmetatable(area, { __index = flib_area })
end

--- Move the area by the given delta.
--- @param self BoundingBox
--- @param delta Position
--- @return BoundingBox
function flib_area.move(self, delta)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  self.left_top.x = self.left_top.x + delta.x
  self.left_top.y = self.left_top.y + delta.y
  self.right_bottom.x = self.right_bottom.x + delta.x
  self.right_bottom.y = self.right_bottom.y + delta.y

  return self
end

--- Rotate the area 90 degrees around its center.
--- @param self BoundingBox
--- @return BoundingBox
function flib_area.rotate(self)
  -- save current properties
  local center = flib_area.center(self)
  local height = flib_area.height(self)
  local width = flib_area.width(self)

  local radius_x = height / 2
  local radius_y = width / 2

  self.left_top.x = center.x - radius_x
  self.right_bottom.x = center.x + radius_x

  self.left_top.y = center.y - radius_y
  self.right_bottom.y = center.y + radius_y

  return self
end

--- Create a new area table from the given area, removing any extra fields and metatables.
---
--- This is useful when passing an area to API functions that will complain about any unknown fields.
--- @param self BoundingBox
--- @return BoundingBox
function flib_area.strip(self)
  return {
    left_top = {
      x = self.left_top.x,
      y = self.left_top.y,
    },
    right_bottom = {
      x = self.right_bottom.x,
      y = self.right_bottom.y,
    },
  }
end

--- Remove keys from the area to create a shorthanded area.
---
--- # Examples
---
--- ```lua
--- local Area = area.from_dimensions({ height = 5, width = 5 }, { x = 0, y = 0 })
--- local stripped_area = area.strip(Area)
--- log(serpent.line(Area)) -- { left_top = { x = -2.5, y = -2.5 }, right_bottom = { x = 2.5, y = 2.5 } }
--- log(serpent.line(stripped_area)) -- { { -2.5, -2.5 }, { 2.5, 2.5 } }
--- ```
--- @param self BoundingBox
--- @return BoundingBox
function flib_area.to_shorthand(self)
  if not self.left_top then
    return self
  end

  return {
    { self.left_top.x, self.left_top.y },
    { self.right_bottom.x, self.right_bottom.y },
  }
end

--- Calculate the width of the area.
--- @param self BoundingBox
--- @return number
function flib_area.width(self)
  if not self.left_top then
    self = flib_area.from_shorthand(self)
  end

  return math.abs(self.right_bottom.x - self.left_top.x)
end

return flib_area
