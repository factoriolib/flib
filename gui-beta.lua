local reverse_defines = require("__flib__.reverse-defines")

local flib_gui = {}

-- navigate a structure to build a GUI
local function recursive_build(parent, structure, refs)
  -- create element
  local elem = parent.add(structure)
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
  -- element actions
  if structure.actions then
    -- do it this way to preserve any other tags
    local tags = elem.tags
    if tags.flib then
      tags.flib[script.mod_name] = {actions = structure.actions}
    else
      tags.flib = {[script.mod_name] = {actions = structure.actions}}
    end
    elem.tags = tags
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

function flib_gui.get_action(e)
  if not e.element then return end
  local tags = e.element.tags.flib
  if tags then
    local mod_tags = tags[script.mod_name]
    if mod_tags then
      local actions = mod_tags.actions
      if actions then
        local action = actions[string.gsub(reverse_defines.events[e.name], "_gui", "")]
        if action then
          return action
        end
      end
    end
  end
end

return flib_gui