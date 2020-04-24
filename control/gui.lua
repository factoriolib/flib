--- @module control.gui
-- @usage local gui = require("__flib__.control.gui")
local gui = {}

local util = require("util")

local string_gmatch = string.gmatch
local string_sub = string.sub

local handlers = {}
local templates = {}

local template_lookup = {}
local handler_lookup = {}

-- table extension functions
local function extend_table(self, data, do_return)
  for k, v in pairs(data) do
    if (type(v) == "table") then
      if (type(self[k] or false) == "table") then
        self[k] = extend_table(self[k], v, true)
      else
        self[k] = table.deepcopy(v)
      end
    else
      self[k] = v
    end
  end
  if do_return then return self end
end
handlers.extend = extend_table
templates.extend = extend_table

local function generate_template_lookup(t, template_string)
  for k, v in pairs(t) do
    if k ~= "extend" and type(v) == "table" then
      local new_string = template_string..k
      if v.type then
        template_lookup[new_string] = v
      else
        generate_template_lookup(v, new_string..".")
      end
    end
  end
end

local function generate_handler_lookup(t, event_string, event_groups, saved_filters)
  event_groups[#event_groups+1] = event_string
  for k, v in pairs(t) do
    if k ~= "extend" then
      local new_string = event_string.."."..k
      -- shortcut syntax: key is a defines.events or a custom-input name, value is just the handler
      if type(v) == "function" then
        handler_lookup[string_sub(new_string, 2, #new_string)] = {
          id = defines.events[k] or k,
          handler = v
        }
      elseif v.handler then
        if not v.id then
          v.id = defines.events[k] or k
        end
        v.group = table.deepcopy(event_groups)
        handler_lookup[string_sub(new_string, 2, #new_string)] = v
      else
        generate_handler_lookup(v, new_string, event_groups, saved_filters)
      end
    end
  end
  event_groups[#event_groups] = nil
end

--- @section Functions

--- Initial setup
-- Must be called at the BEGINNING of on_init, before any GUI functions are used
function gui.on_init()
  if not global.__flib then
    global.__flib = {gui={}}
  else
    global.__flib.gui = {}
  end
end

--- Generate template and handler lookup tables
-- Must be called at the END of on_init and on_load
function gui.bootstrap_postprocess()
  local template_lookup = template_lookup
  local handler_lookup = handler_lookup
  generate_template_lookup(templates, "")
  generate_handler_lookup(handlers, "", {}, global.__flib.gui)
end

-- navigate a structure to build a GUI
local function recursive_build(parent, structure, output, filters, player_index)
  -- load template
  if structure.template then
    for k,v in pairs(template_lookup[structure.template]) do
      structure[k] = structure[k] or v
    end
  end
  local elem
  -- special logic if this is a tab-and-content
  if structure.type == "tab-and-content" then
    local tab, content
    output, filters, tab = recursive_build(parent, structure.tab, output, filters, player_index)
    output, filters, content = recursive_build(parent, structure.content, output, filters, player_index)
    parent.add_tab(tab, content)
  else
    -- create element
    elem = parent.add(structure)
    -- apply style modifications
    if structure.style_mods then
      for k, v in pairs(structure.style_mods) do
        elem.style[k] = v
      end
    end
    -- apply modifications
    if structure.mods then
      for k, v in pairs(structure.mods) do
        elem[k] = v
      end
    end
    -- register handlers
    if structure.handlers then
      local elem_index = elem.index
      local name = structure.handlers
      
    end
    -- add to output table
    if structure.save_as then
      -- recursively create tables as needed
      local prev = output
      local prev_key
      local nav
      for key in string_gmatch(structure.save_as, "([^%.]+)") do
        prev = prev_key and prev[prev_key] or prev
        nav = prev[key]
        if nav then
          prev = nav
        else
          prev[key] = {}
          prev_key = key
        end
      end
      prev[prev_key] = elem
    end
    -- add children
    local children = structure.children
    if children then
      for i=1,#children do
        output, filters = recursive_build(elem, children[i], output, filters, player_index)
      end
    end
  end
  return output, filters, elem
end

function gui.build(parent, structures)
  local output = {}
  local filters = {}
  for i=1,#structures do
    output, filters = recursive_build(
      parent,
      structures[i],
      output,
      filters,
      parent.player_index or parent.player.index
    )
  end
  return output, filters
end

gui.templates = templates
gui.handlers = handlers

--- @Concepts GuiFilter
-- One of the following:
-- - A @{string} corresponding to an element's name.
--   - Partial names may be matched by separating the common part from the unique part with two underscores.
-- - An @{integer} corresponding to an element's index.

return gui