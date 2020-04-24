--- @module control.gui
-- @usage local gui = require("__flib__.control.gui")
local gui = {}

local util = require("util")

local string_gmatch = string.gmatch
local string_gsub = string.gsub
local string_sub = string.sub

local handlers = {}
local templates = {}

local template_lookup = {}
local handler_lookup = {}
local handler_groups = {}

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

local function generate_handler_lookup(t, event_string, groups, saved_filters)
  groups[#groups+1] = event_string
  for k, v in pairs(t) do
    if k ~= "extend" then
      local new_string = event_string.."."..k
      -- shortcut syntax: key is a defines.events or a custom-input name, value is just the handler
      if type(v) == "function" then
        v = {
          id = defines.events[k] or k,
          handler = v
        }
      end
      if v.handler then
        v.id = v.id or defines.events[k] or k
        handler_lookup[new_string] = v
        -- assign handler to groups
        for i=1,#groups do
          local group = handler_groups[groups[i]]
          if group then
            group[#group+1] = new_string
          else
            handler_groups[groups[i]] = {new_string}
          end
        end
      else
        generate_handler_lookup(v, new_string, groups, saved_filters)
      end
    end
  end
  groups[#groups] = nil
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
  generate_template_lookup(templates, "")
  -- go one level deep before calling the function, to avoid adding an unnecessary prefix to all group names
  for k, v in pairs(handlers) do
    generate_handler_lookup(v, k, {}, global.__flib.gui)
  end
end

--- Update element filters for the given event.
-- @tparam defines.events|uint|string id
-- @tparam uint player_index
-- @tparam GuiFilters filters
-- @tparam string mode One of "add", "remove", or "overwrite".
function gui.update_filters(id, player_index, filters, mode)
  -- get data tables, or create them if needed
  local __gui = global.__flib.gui
  local saved_filters = __gui[player_index]
  if not saved_filters then
    __gui[player_index] = {[id]={}}
    saved_filters = __gui[player_index]
  end
  local event_filters = saved_filters[id]
  if not event_filters then
    saved_filters[id] = {}
    event_filters = saved_filters[id]
  end

  -- update filters
  mode = mode or "overwrite"
  if mode == "add" then
    for filter, handler_path in pairs(filters) do
      event_filters[filter] = handler_path
    end
  elseif mode == "remove" then
    for filter in pairs(filters) do
      event_filters[filter] = nil
    end
  elseif mode == "overwrite" then
    saved_filters = filters
  else
    error("Invalid GUI filter update mode ["..mode.."]")
  end

  -- destroy tables if they're not needed any longer
  if mode == "remove" or mode == "overwrite" then
    if table_size(event_filters) == 0 then
      saved_filters[id] = nil
    end
    if table_size(saved_filters) == 0 then
      __gui[player_index] = nil
    end
  end
end

--- Dispatch GUI handlers for the given function.
-- @tparam Concepts.EventData e
function gui.dispatch_handlers(e)
  if not e.element or not e.player_index then return end
  local element = e.element
  local element_name = string_gsub(element.name, "__.*", "")
  local player_filters = global.__flib.gui[e.player_index]
  if not player_filters then return end
  local filters = player_filters[e.name]
  if not filters then return end
  local handler_name = filters[element.index] or filters[element_name]
  if handler_name then
    handler_lookup[handler_name].handler(e)
  end
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
      local group = handler_groups[structure.handlers]
      if not group then error("Invalid GUI handler name ["..structure.handlers.."]") end
      for i=1,#group do
        local name = group[i]
        local id = handler_lookup[name].id
        gui.update_filters(id, player_index, {[elem_index]=name}, "add")
        local saved_filters = filters[id]
        if not saved_filters then
          filters[id] = {[elem_index]=name}
        else
          saved_filters[elem_index] = name
        end
      end
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

--- Build a GUI structure.
-- @tparam parent LuaGuiElement
-- @tparam GuiStructure[] structures
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

-- merge tables
local function extend_table(self, t, do_return)
  for k, v in pairs(t) do
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

--- Add content to the GUI templates table.
-- TODO: Explain templating.
-- @tparam table t
function gui.add_templates(t)
  extend_table(templates, t)
end

--- Add content to the GUI handlers table.
-- TODO: Explain handlers.
-- @tparam table t
function gui.add_handlers(t)
  extend_table(handlers, t)
end

--- Register all GUI events to go through the module.
function gui.register_events()
  for name, id in pairs(defines.events) do
    if string_sub(name, 1, 6) == "on_gui" then
      script.on_event(id, function(e) gui.dispatch_handlers(e) end)
    end
  end
end

gui.templates = templates
gui.handlers = handlers
gui.handler_groups = handler_groups

--- @Concepts GuiStructure
-- A GUI structure. Basic format is a table corresponding to a LuaGuiElement's constructor.
-- TODO Raiguard document all properties

--- @Concepts GuiFilters
-- Table @{GuiFilter} -> string. Each string corresponds to a GUI handler name. When an element matching the given
-- filter raises an event, the handler corresponding to the handler name is fired.
-- TODO Raiguard expound on this

--- @Concepts GuiFilter
-- One of the following:
-- - A @{string} corresponding to an element's name.
--   - Partial names may be matched by separating the common part from the unique part with two underscores.
-- - An @{integer} corresponding to an element's index.

return gui