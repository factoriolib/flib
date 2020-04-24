--- @module control.gui
-- @usage local gui = require("__flib__.control.gui")
local gui = {}

local event = require("__flib__.control.event")
local util = require("util")

local string_gmatch = string.gmatch
local string_gsub = string.gsub

local handlers = {}
local templates = {}

local template_lookup = {}
local handler_lookup = {} -- holds GUI handler data for this module

-- pass-through handler for all GUI events - checks GUI filters and only calls the real handler if there's a match
local function event_matcher(e)
  if not e.conditional_name then return end
  local element = e.element
  local handler = handler_lookup[e.conditional_name]
  local player_filters = global.__flib.gui.event_filters[e.player_index]
  if player_filters and e.player_index then
    local filters = player_filters[e.conditional_name]
    if player_filters and element then
      local element_name = string_gsub(element.name, "__.*", "")
      if filters[element.index] or filters[element_name] then
        handler(e)
      end
    end
  end
end

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
  for k,v in pairs(t) do
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

local function generate_handlers(output, t, event_string, event_groups)
  event_groups[#event_groups+1] = event_string
  for k,v in pairs(t) do
    if k ~= "extend" then
      local new_string = event_string.."."..k
      if type(v) == "function" then
        -- shortcut syntax: key is a defines.events or a custom-input name, value is just the handler
        output[new_string] = {
          id = defines.events[k] or k,
          handler = event_matcher,
          group = table.deepcopy(event_groups)
        }
        handler_lookup[new_string] = v
      elseif v.handler then
        if not v.id then
          v.id = defines.events[k] or k
        end
        v.group = table.deepcopy(event_groups)
        output[new_string] = v
      else
        output = generate_handlers(output, v, new_string, event_groups)
      end
    end
  end
  event_groups[#event_groups] = nil
  return output
end

event.on_init(function()
  global.__flib.gui = {event_filters={}}
end)

-- create template lookup and register conditional GUI handlers
event.register({"on_init_postprocess", "on_load_postprocess"}, function(e)
  -- construct template lookup table
  generate_template_lookup(templates, "")
  -- create and register conditional handlers for the GUI events
  event.register_conditional(generate_handlers({}, handlers, "gui", {}), handler_lookup)
end)

--- @section Events

--- Updates filters for a GUI handler.
-- If the gui handler isn't enabled, it will enable it.
-- If the filters list is emptied in the process, it will disable the handler.
-- @param name string The name of the handler you wish to update.
-- @param player_index int
-- @param filters GuiFilter[]
-- @param[opt="overwrite"] mode string One of "add", "remove", or "overwrite"
-- @return GuiFilter[] The updated filters.
function gui.update_filters(name, player_index, filters, mode)
  local __gui = global.__flib.gui
  local player_filters = __gui.event_filters[player_index]
  if not player_filters then
    __gui.event_filters[player_index] = {}
    player_filters = __gui.event_filters[player_index]
  end
  local handler_filters = player_filters[name]
  if not handler_filters then
    event.enable(name, player_index)
    player_filters[name] = {}
    handler_filters = player_filters[name]
  end

  if type(filters) ~= "table" then
    filters = {filters}
  end

  mode = mode or "overwrite"
  if mode == "add" then
    for i=1,#filters do
      handler_filters[filters[i]] = true
    end
  elseif mode == "remove" then
    for i=1,#filters do
      handler_filters[filters[i]] = nil
    end
    if table_size(handler_filters) == 0 then
      disable_handler = true
    end
  elseif mode == "overwrite" then
    local filters_size = #filters
    if filters_size == 0 then
      disable_handler = true
    else
      local new_filters = {}
      for i=1,#filters do
        new_filters[filters[i]] = true
      end
      player_filters[name] = new_filters
    end
  else
    error("Invalid GUI filter update mode ["..mode.."]")
  end

  if disable_handler then
    event.disable(name, player_index)
    player_filters[name] = nil
    if table_size(player_filters) == 0 then
      __gui.event_filters[player_index] = nil
    end
  end
end

--- @section Construction

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
      for k,v in pairs(structure.style_mods) do
        elem.style[k] = v
      end
    end
    -- apply modifications
    if structure.mods then
      for k,v in pairs(structure.mods) do
        elem[k] = v
      end
    end
    -- register handlers
    if structure.handlers then
      local elem_index = elem.index
      local name = "gui."..structure.handlers
      local group = event.conditional_event_groups[name]
      if not group then error("Invalid GUI event group: "..name) end
      for i=1,#group do
        gui.update_filters(group[i], player_index, elem_index, "add")
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

return gui