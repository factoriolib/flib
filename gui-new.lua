local flib_gui = {}

-- SPECIAL KEYS

local elem_event_keys = {}
for key, id in pairs(defines.events) do
  if string.find(key, "gui") then
    elem_event_keys[string.gsub(key, "_gui", "")] = id
  end
end

function flib_gui.init()
  if global.__flib then
    global.__flib.gui = {players = {}}
  else
    global.__flib = {
      gui = {players = {}}
    }
  end
end

function flib_gui.register_handlers()
  for name, id in pairs(defines.events) do
    if string.find(name, "gui") then
      script.on_event(id, flib_gui.dispatch)
    end
  end
end

-- navigate a structure to build a GUI
local function recursive_build(root_name, parent, structure, refs, assigned_handlers, player_index)
  -- process structure
  local elem
  local structure_type = structure.type
  if structure_type == "tab-and-content" then
    local tab, content
    refs, assigned_handlers, tab = recursive_build(
      root_name,
      parent,
      structure.tab,
      refs,
      assigned_handlers,
      player_index
    )
    refs, assigned_handlers, content = recursive_build(
      root_name,
      parent,
      structure.content,
      refs,
      assigned_handlers,
      player_index
    )
    parent.add_tab(tab, content)
  else
    -- create element
    elem = parent.add(structure)
    -- iterate over properties
    local elem_index = elem.index
    for key, value in pairs(structure) do
      if key ~= "type" and key ~= "children" then
        local event_id = elem_event_keys[key]
        if event_id then
          flib_gui.add_handler(player_index, elem_index, event_id, value, root_name)
          assigned_handlers[elem_index] = true
        end
      end
    end
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
        refs, assigned_handlers = recursive_build(root_name, elem, children[i], refs, assigned_handlers, player_index)
      end
    end
  end

  return refs, assigned_handlers, elem
end

function flib_gui.build(parent, structures)
  local refs = {}
  local assigned_handlers = {}
  local player_index = parent.player_index or parent.player.index
  for i = 1, #structures do
    refs, assigned_handlers = recursive_build(
      "TODO",
      parent,
      structures[i],
      refs,
      assigned_handlers,
      player_index
    )
  end
  return refs, assigned_handlers
end

function flib_gui.dispatch(event_data)
  local element = event_data.element
  local player_index = event_data.player_index
  if not element or not player_index then return false end

  local player_data = global.__flib.gui.players[player_index]
  if not player_data then return false end

  local elem_index = element.index

  local elem_handlers = player_data.handlers[elem_index]
  if not elem_handlers then return false end

  local handler_data = elem_handlers[event_data.name]
  if handler_data then
    -- local updater_data = table.shallow_merge(event_data, {msg = handler_data.msg})
    -- TODO dispatch updater
    game.print(serpent.block{event_data, handler_data.msg})
    return true
  else
    return false
  end
end

function flib_gui.add_handler(player_index, matcher, event_id, msg, root_name)
  local players = global.__flib.gui.players

  local player_data = players[player_index]
  if not player_data then
    players[player_index] = {handlers = {}}
    player_data = players[player_index]
  end

  local player_handlers = player_data.handlers

  local elem_data = player_handlers[matcher]
  if not elem_data then
    player_handlers[matcher] = {}
    elem_data = player_handlers[matcher]
  end

  elem_data[event_id] = {
    msg = msg,
    root_name = root_name
  }
end

function flib_gui.remove_handler(player_index, matcher, event_id)
  local players = global.__flib.gui.players

  local player_data = players[player_index]
  if not player_data then return end

  local player_handlers = player_data.handlers
  local elem_data = player_handlers[matcher]
  if not elem_data then return end

  elem_data[event_id] = nil

  if table_size(elem_data) == 0 then
    player_handlers[matcher] = nil
    if table_size(player_handlers) == 0 then
      players[player_index] = nil
    end
  end

end

return flib_gui