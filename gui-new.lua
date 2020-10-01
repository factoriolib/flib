local flib_gui = {}

function flib_gui.init()
  if global.__flib then
    global.__flib.gui = {}
  else
    global.__flib = {gui = {}}
  end
end

-- navigate a structure to build a GUI
local function recursive_build(parent, structure, refs, assigned_handlers, player_index)
  -- process structure
  local elem
  local structure_type = structure.type
  if structure_type == "tab-and-content" then
    local tab, content
    refs, assigned_handlers, tab = recursive_build(parent, structure.tab, refs, assigned_handlers, player_index)
    refs, assigned_handlers, content = recursive_build(parent, structure.content, refs, assigned_handlers, player_index)
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
    if structure.elem_mods then
      for k, v in pairs(structure.elem_mods) do
        elem[k] = v
      end
    end
    -- add to refs table
    -- TODO support multiple levels with an array?
    local structure_ref = structure.ref
    if structure_ref then
      refs[structure_ref] = elem
    end
    -- add children
    local children = structure.children
    if children then
      for i = 1, #children do
        refs, assigned_handlers = recursive_build(elem, children[i], refs, assigned_handlers, player_index)
      end
    end
  end

  return refs, assigned_handlers, elem
end

function flib_gui.build(parent, structures)
  local output = {}
  local filters = {}
  local player_index = parent.player_index or parent.player.index
  for i = 1, #structures do
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

return flib_gui