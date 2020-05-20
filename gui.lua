--- GUI structuring tools and event handling.
-- @module gui
-- @usage local gui = require("__flib__.gui")
local flib_gui = {}

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

local function generate_handler_lookup(t, event_string, groups)
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
        v.filters = {}
        v.groups = table.deepcopy(groups)
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
        generate_handler_lookup(v, new_string, groups)
      end
    end
  end
  groups[#groups] = nil
end

local function generate_filter_lookup()
  -- add filter lookup to each handler
  for _, players in pairs(global.__flib.gui) do
    for player_index, filters in pairs(players) do
      if player_index ~= "__size" then
        for filter, handler_name in pairs(filters) do
          if filter ~= "__size" then
            local handler_filters = handler_lookup[handler_name].filters
            local player_filters = handler_filters[player_index]
            if player_filters then
              player_filters[filter] = filter
              player_filters.__size = player_filters.__size + 1
            else
              handler_filters[player_index] = {__size=1, [filter]=filter}
            end
          end
        end
      end
    end
  end
end

--- Initial setup. Must be called at the BEGINNING of on_init, before any GUI functions are used.
-- If adding the module to an existing mod, this must be called in on_configuration_changed for that version as well.
function flib_gui.init()
  if not global.__flib then
    global.__flib = {gui={}}
  else
    global.__flib.gui = {}
  end
end

--- Generate template and handler lookup tables.
-- Must be called at the END of on_init and on_load
function flib_gui.build_lookup_tables()
  generate_template_lookup(templates, "")
  -- go one level deep before calling the function, to avoid adding an unnecessary prefix to all group names
  for k, v in pairs(handlers) do
    generate_handler_lookup(v, k, {})
  end
  if global.__flib and global.__flib.gui then
    generate_filter_lookup()
  end
end

--- Add or remove GUI filters to or from a handler or group of handlers.
-- @tparam string name The handler name, or group name.
-- @tparam uint player_index
-- @tparam GuiFilter[] filters An array of filters.
-- @tparam string mode One of "add" or "remove".
function flib_gui.update_filters(name, player_index, filters, mode)
  local handler_names = handler_groups[name] or {name}
  for hi=1,#handler_names do
    local handler_name = handler_names[hi]
    local handler_data = handler_lookup[handler_name]
    if not handler_data then error("GUI handler ["..handler_name.."] does not exist!") end
    local id = handler_data.id
    local handler_filters = handler_data.filters

    -- saved filters table (in global)
    local __gui = global.__flib.gui
    local saved_event_filters = __gui[id]
    if not saved_event_filters then
      __gui[id] = {__size=1, [player_index]={__size=0}}
      saved_event_filters = __gui[id]
    end
    local saved_player_filters = saved_event_filters[player_index]
    if not saved_player_filters then
      saved_event_filters[player_index] = {__size=0}
      saved_event_filters.__size = saved_event_filters.__size + 1
      saved_player_filters = saved_event_filters[player_index]
    end

    -- handler filters table (in lookup)
    local handler_player_filters = handler_filters[player_index]
    if not handler_player_filters then
      handler_filters[player_index] = {__size=0}
      handler_player_filters = handler_filters[player_index]
    end

    -- update filters
    mode = mode or "add"
    if mode == "add" then
      for _, filter in pairs(filters) do
        saved_player_filters[filter] = handler_name
        saved_player_filters.__size = saved_player_filters.__size + 1
        handler_player_filters[filter] = filter
        handler_player_filters.__size = handler_player_filters.__size + 1
      end
    elseif mode == "remove" then
      -- if a filters table wasn't provided, remove all of them
      for key, filter in pairs(filters or handler_player_filters) do
        if key ~= "__size" then
          saved_player_filters[filter] = nil
          saved_player_filters.__size = saved_player_filters.__size - 1
          handler_player_filters[filter] = nil
          handler_player_filters.__size = handler_player_filters.__size - 1
        end
      end

      -- clean up empty tables
      if saved_player_filters.__size == 0 then
        saved_event_filters[player_index] = nil
        saved_event_filters.__size = saved_event_filters.__size - 1
        if saved_event_filters.__size == 0 then
          __gui[id] = nil
        end
      end
      if handler_player_filters.__size == 0 then
        handler_filters[player_index] = nil
      end
    else
      error("Invalid GUI filter update mode ["..mode.."]")
    end
  end
end

--- Remove all GUI filters for the given player.
-- @tparam uint player_index
function flib_gui.remove_player_filters(player_index)
  local filters_table = global.__flib.gui
  for event_name, event_filters in pairs(filters_table) do
    local player_filters = event_filters[player_index]
    if player_filters then
      event_filters[player_index] = nil
      event_filters.__size = event_filters.__size - 1
      if event_filters.__size == 0 then
        filters_table[event_name] = nil
      end
    end
  end
end

--- Dispatch GUI handlers for the given event.
-- @tparam Concepts.EventData e
-- @treturn boolean If a handler was dispatched.
function flib_gui.dispatch_handlers(e)
  if not e.element or not e.player_index then return false end
  local element = e.element
  local element_name = string_gsub(element.name, "__.*", "")
  local event_filters = global.__flib.gui[e.name]
  if not event_filters then return false end
  local player_filters = event_filters[e.player_index]
  if not player_filters then return false end
  local handler_name = player_filters[element.index] or player_filters[element_name]
  if handler_name then
    handler_lookup[handler_name].handler(e)
    return true
  else
    return false
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

  -- process structure
  local elem
  local structure_type = structure.type
  if structure_type == "condition" then
    if structure.condition then
      -- add children
      local children = structure.children
      if children then
        for i=1,#children do
          output, filters = recursive_build(parent, children[i], output, filters, player_index)
        end
      end
    end
  elseif structure_type == "tab-and-content" then
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
        local saved_filters = filters[name]
        if not saved_filters then
          filters[name] = {elem_index}
        else
          saved_filters[#saved_filters+1] = elem_index
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
-- @treturn GuiOutputTable output
-- @treturn GuiOutputFiltersTable filters
function flib_gui.build(parent, structures)
  local output = {}
  local filters = {}
  local player_index = parent.player_index or parent.player.index
  for i=1,#structures do
    output, filters = recursive_build(
      parent,
      structures[i],
      output,
      filters,
      player_index
    )
  end
  for name, filters_table in pairs(filters) do
    flib_gui.update_filters(name, player_index, filters_table, "add")
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
function flib_gui.add_templates(t)
  extend_table(templates, t)
end

--- Add content to the GUI handlers table.
-- TODO: Explain handlers.
-- @tparam table t
function flib_gui.add_handlers(t)
  extend_table(handlers, t)
end

--- Register all GUI handlers to go through the module.
function flib_gui.register_handlers()
  for name, id in pairs(defines.events) do
    if string_sub(name, 1, 6) == "on_gui" then
      script.on_event(id, function(e) flib_gui.dispatch_handlers(e) end)
    end
  end
end

flib_gui.templates = templates
flib_gui.handlers = handlers
flib_gui.handler_lookup = handler_lookup
flib_gui.handler_groups = handler_groups

--- @Concept GuiFilter
-- One of the following:
-- <ul>
--   <li>A @{string} corresponding to an element's name. Partial names may be matched by separating the common section
--   from the unique section with two underscores `__`.</li>
--   <li>A @{uint} corresponding to an element's index.</li>
-- </ul>

--- @Concept GuiStructure
-- A GUI structure in its basic form takes on the format of the @{LuaGuiElement} you are creating, and must have all of
-- the required parameters for that element. There are several additional parameters that define custom behavior:
--
-- <strong><em>type</em></strong>
--
-- Alongside the usual @{LuaGuiElement} types, there are two additional types added by the module:
-- <ul>
--   <li><strong>condition:</strong> Accepts the `condition` and `children` parameters only.</li>
--   <li><strong>tab-and-content:</strong> Accepts the `tab` and `content` parameters only.</li>
-- </ul>
--
-- <strong><em>condition</em></strong>
--
-- For `condition` types only. If true, the children of this @{GuiStructure} will be added to the parent of this
-- @{GuiStructure}. If false, they will not.
--
-- <strong><em>tab</em></strong>
--
-- For `tab-and-content` types only. A @{GuiStructure} defining a tab to be placed in a tabbed-pane.
--
-- <strong><em>content</em></strong>
--
-- For `tab-and-content` types only. A @{GuiStructure} defining the content that will be shown when the corresponding
-- tab is active.
--
-- <strong><em>style_mods</em></strong>
--
-- A key -> value dictionary defining edits to make to the element's style. Available properties are listed in
-- @{LuaStyle}.
--
-- <strong><em>mods</em></strong>
--
-- A key -> value dictionary defining edits to make to the element. Available properties are listed in @{LuaGuiElement}.
--
-- <strong><em>handlers</em></strong>
--
-- A @{string} defining group of functions in the gui.handlers table, added through @{gui.add_handlers}. The element
-- will be registered to those handlers, and when the events are raised by the game relating to this element, the
-- corresponding handlers will be dispatched.
--
-- <strong><em>save_as</em></strong>
--
-- A @{string} defining a table path to save this element to, in the first return value of @{gui.build}. This is a
-- dot-deliminated list of nested table names, followed by a key to save the element as. The module will construct the
-- output table dynamically based on the contents of `save_as` throughout the structure.
--
-- <strong><em>children</em></strong>
--
-- An array of @{GuiStructure} that will be added as children of this element.

--- @Concept GuiOutputTable
-- A table with a custom structure as defined in @{GuiStructure}.save_as. Consists of nested tables and key ->
-- @{LuaGuiElement} pairs.

--- @Concept GuiOutputFiltersTable
-- Dictionary @{event.EventId} -> (Dictionary @{GuiFilter} -> string). A mapping of event IDs to the filters assigned
-- to it by this structure, using @{GuiStructure}.handlers.
-- @usage
-- {
--   [defines.events.on_gui_closed] = {
--     [23] = "window.on_gui_closed"
--   },
--   [defines.events.on_gui_click] = {
--     [21] = "titlebar.close_button.on_gui_click",
--     [30] = "content_pane.ingredients_list.ingredient_button.on_gui_click"
--   },
--   [custom_mod_event] = {
--     [31] = "content_pane.something_or_another"
--   }
-- }

return flib_gui