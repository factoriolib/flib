local reverse_defines = require("__flib__.reverse-defines")
local table = require("__flib__.table")

local flib_gui = {}

-- FIELDS

local handlers = {}

-- SETUP FUNCTIONS

function flib_gui.add_handlers(tbl)
  -- if `tbl.handlers` exists, use it, else use the table directly
  for name, func in pairs(tbl.handlers or tbl) do
    handlers[name] = func
  end
end

function flib_gui.hook_gui_events()
  for name, id in pairs(defines.events) do
    if string.find(name, "gui") then
      script.on_event(id, flib_gui.dispatch)
    end
  end
end

-- FUNCTIONS

-- navigate a structure to build a GUI
local function recursive_build(parent, structure, refs)
  -- create element
  local elem = parent.add(structure)
  -- reset tags so they can be added back in later with a subtable
  elem.tags = {}
  -- style modifications
  if structure.style_mods then
    for k, v in pairs(structure.style_mods) do
      elem.style[k] = v
    end
  end
  -- element modifications
  if structure.elem_mods then
    for k, v in pairs(structure.elem_mods) do
      elem[k] = v
    end
  end
  -- element tags
  if structure.tags then
    flib_gui.set_tags(elem, structure.tags)
  end
  -- element handlers
  if structure.handlers then
    -- do it this way to preserve any other tags
    local tags = elem.tags
    if tags[script.mod_name] then
      tags[script.mod_name].flib_handlers = structure.handlers
    else
      tags[script.mod_name] = {flib_handlers = structure.handlers}
    end
    elem.tags = tags
  end
  -- element reference
  if structure.ref then
    -- recursively create tables as needed
    local prev = refs
    local prev_key
    local nav
    for _, key in pairs(structure.ref) do
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
    for i = 1, #children do
      recursive_build(elem, children[i], refs)
    end
  end
  -- add tabs
  local tabs = structure.tabs
  if tabs then
    for i = 1, #tabs do
      local tab_and_content = tabs[i]
      local tab = recursive_build(elem, tab_and_content.tab, refs)
      local content = recursive_build(elem, tab_and_content.content, refs)
      elem.add_tab(tab, content)
    end
  end

  return elem
end

function flib_gui.build(parent, structures)
  local refs = {}
  for i = 1, #structures do
    recursive_build(
      parent,
      structures[i],
      refs
    )
  end
  return refs
end

function flib_gui.dispatch(e)
  local elem = e.element
  if not elem then return false end

  local mod_tags = elem.tags[script.mod_name]
  if not mod_tags then return end

  local elem_handlers = mod_tags.flib_handlers
  if not elem_handlers then return end

  local event_name = string.gsub(reverse_defines.events[e.name] or "", "_gui", "")
  local handler_name = elem_handlers[event_name]
  if not handler_name then return false end

  local handler = handlers[handler_name]
  if not handler then return false end

  handler(e)

  return true
end

function flib_gui.get_tags(elem)
  return elem.tags[script.mod_name] or {}
end

function flib_gui.set_tags(elem, tags)
  local elem_tags = elem.tags
  elem_tags[script.mod_name] = tags
  elem.tags = elem_tags
end

function flib_gui.delete_tags(elem)
  local elem_tags = elem.tags
  elem_tags[script.mod_name] = nil
  elem.tags = elem_tags
end

function flib_gui.update_tags(elem, updates)
  local elem_tags = elem.tags
  local existing = elem_tags[script.mod_name]

  if not existing then
    elem_tags[script.mod_name] = {}
    existing = elem_tags[script.mod_name]
  end

  for k, v in pairs(updates) do
    existing[k] = v
  end

  elem.tags = elem_tags
end

return flib_gui