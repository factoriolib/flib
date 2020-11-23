-- FLIB BETA GUI MODULE
--
-- Welcome, script explorer! This is a beta version of flib's new GUI module. This code is fairly stable and can be used
-- in mods, but is not guaranteed to keep working between versions. Use at your own risk!

local reverse_defines = require("__flib__.reverse-defines")

local flib_gui = {}

-- `ACTIONS` FUNCTIONS

function flib_gui.hook_events(func)
  for name, id in pairs(defines.events) do
    if string.find(name, "gui") then
      script.on_event(id, func)
    end
  end
end

-- retrieves the action message from the element's tags
function flib_gui.read_action(e)
  local elem = e.element
  if not elem then return end

  local mod_tags = elem.tags[script.mod_name]
  if not mod_tags then return end

  local elem_actions = mod_tags.flib
  if not elem_actions then return end

  local event_name = string.gsub(reverse_defines.events[e.name] or "", "_gui", "")
  local msg = elem_actions[event_name]

  return msg
end

-- BUILDING AND UPDATING FUNCTIONS

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
  -- element actions
  if structure.actions then
    flib_gui.update_tags(elem, {flib = structure.actions})
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

local function recursive_update(elem, updates)
  if updates.cb then
    updates.cb(elem)
  end

  if updates.style_mods then
    for key, value in pairs(updates.style_mods) do
      elem.style[key] = value
    end
  end

  if updates.elem_mods then
    for key, value in pairs(updates.elem_mods) do
      elem[key] = value
    end
  end

  -- TODO: tags, handlers/actions

  if updates.children then
    local elem_children = elem.children
    for i, child_updates in ipairs(updates.children) do
      if elem_children[i] then
        recursive_update(elem_children[i], child_updates)
      end
    end
  end

  if updates.tabs then
    local elem_tabs = elem.tabs
    for i, tab_and_content_updates in pairs(updates.tabs) do
      local elem_tab_and_content = elem_tabs[i]
      if elem_tab_and_content then
        local tab = elem_tab_and_content.tab
        local tab_updates = tab_and_content_updates.tab
        if tab and tab_updates then
          recursive_update(tab, tab_updates)
        end
        local content = elem_tab_and_content.content
        local content_updates = tab_and_content_updates.content
        if content and content_updates then
          recursive_update(content, content_updates)
        end
      end
    end
  end
end

function flib_gui.update(elem, updates)
  recursive_update(elem, updates)
end

-- TAGS FUNCTIONS

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