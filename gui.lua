--- GUI structuring tools and event handling.
-- @module gui
-- @alias flib_gui
-- @usage local gui = require("__flib__.gui")
-- @see gui.lua

local mod_name = script.mod_name
local gui_event_defines = {}

local event_id_to_string_mapping = {}
for name, id in pairs(defines.events) do
  if string.find(name, "^on_gui") then
    gui_event_defines[name] = id
    event_id_to_string_mapping[id] = string.gsub(name, "^on_gui", "on")
  end
end

local flib_gui = {}

-- `ACTIONS` FUNCTIONS

--- Provide a callback to be run for GUI events.
-- @tparam function callback
-- @see gui.read_action
-- @usage
-- gui.hook_events(function(e)
--   local msg = gui.read_action(e)
--   if msg then
--     -- read the action to determine what to do
--   end
-- end)
function flib_gui.hook_events(callback)
  local on_event = script.on_event
  for _, id in pairs(gui_event_defines) do
    on_event(id, callback)
  end
end

--- Retrieve the action message from a GUI element's tags.
-- @tparam EventData event_data
-- @treturn any|nil The element's action for this GUI event.
-- @usage
-- event.on_gui_click(function(e)
--   local action = gui.read_action(e)
--   if action then
--     -- do stuff
--   end
-- end)
function flib_gui.read_action(event_data)
  local elem = event_data.element
  if not elem or not elem.valid then return end

  local mod_tags = elem.tags[mod_name]
  if not mod_tags then return end

  local elem_actions = mod_tags.flib
  if not elem_actions then return end

  local event_name = event_id_to_string_mapping[event_data.name]
  local msg = elem_actions[event_name]

  return msg
end

-- BUILDING AND UPDATING FUNCTIONS

-- navigate a structure to build a GUI
local function recursive_build(parent, structure, refs)
  -- If the structure has no type, just ignore it
  -- This is to make it possible to pass unit types `{}` to represent "no element" without breaking things
  if not structure.type then return end

  -- Prepare tags
  local original_tags = structure.tags
  local tags = original_tags or {}
  local actions = structure.actions
  local tags_flib = tags.flib
  tags.flib = actions
  structure.tags = {[mod_name] = tags}

  -- Make the game not convert these into a property tree for no reason
  structure.actions = nil
  -- Substructures can be defined in special tables or as the array portion of this structure
  local substructures
  local substructures_len = #structure
  if substructures_len > 0 then
    if structure.children or structure.tabs then
      error("Children or tab-and-content pairs must ALL be in the array portion, or a subtable. Not both at once!")
    end
    substructures = {}
    for i = 1, substructures_len do
      substructures[i] = structure[i]
      structure[i] = nil
    end
  else
    substructures = structure.children or structure.tabs
    structure.children = nil
    structure.tabs = nil
  end

  -- Create element
  local elem = parent.add(structure)

  -- Restore structure
  structure.tags = original_tags
  structure.actions = actions
  tags.flib = tags_flib

  local style_mods = structure.style_mods
  if style_mods then
    for k, v in pairs(style_mods) do
      elem.style[k] = v
    end
  end

  local elem_mods = structure.elem_mods
  if elem_mods then
    for k, v in pairs(elem_mods) do
      elem[k] = v
    end
  end

  local ref = structure.ref
  if ref then
    -- Recursively create tables as needed
    local prev = refs
    local ref_length = #ref
    for i = 1, ref_length - 1 do
      local current_key = ref[i]
      local current = prev[current_key]
      if not current then
        current = {}
        prev[current_key] = current
      end
      prev = current
    end
    prev[ref[ref_length]] = elem
  end

  -- Substructures
  if substructures then
    if structure.type == "tabbed-pane" then
      local add_tab = elem.add_tab
      for i = 1, #substructures do
        local tab_and_content = substructures[i]
        if not (tab_and_content.tab and tab_and_content.content) then
          error("TabAndContent must have `tab` and `content` fields")
        end
        local tab = recursive_build(elem, tab_and_content.tab, refs)
        local content = recursive_build(elem, tab_and_content.content, refs)
        add_tab(tab, content)
      end
    else
      for i = 1, #substructures do
        recursive_build(elem, substructures[i], refs)
      end
    end
  end

  return elem
end

--- Build a GUI based on the given structure(s).
-- @tparam LuaGuiElement parent The parent GUI element where the new GUI will be located.
-- @tparam GuiBuildStructure[] structures The GUIs to build.
-- @treturn table @{LuaGuiElement} references and subtables, built based on the values of `ref` throughout the
-- @{GuiBuildStructure}.
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

--- Build a single element based on a GuiStructure.
-- This is to allow use of `style_mods`, `actions` and `tags` without needing to use `gui.build()` for a single element.
--
-- Unlike `gui.build()`, the element will be automatically returned from the function without needing to use `ref`. If
-- you need to obtain references to children of this element, use `gui.build()` instead.
-- @tparam LuaGuiElement parent The parent GUI element where this new element will be located.
-- @tparam GuiBuildStructure structure The element to build.
-- @treturn @{LuaGuiElement} A reference to the element that was created.
function flib_gui.add(parent, structure)
  -- Just in case they had a ref in the structure already, extract it
  local previous_ref = structure.ref
  -- Put in a known ref that we can use later
  structure.ref = {"FLIB_ADD_ROOT"}
  -- Build the element
  local refs = {}
  recursive_build(
    parent,
    structure,
    refs
  )
  -- Restore the previous ref
  structure.ref = previous_ref
  -- Return the element
  return refs.FLIB_ADD_ROOT
end

local function recursive_update(elem, updates)
  if updates.cb then
    updates.cb(elem)
  end

  if updates.style then
    elem.style = updates.style
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

  if updates.tags then
    flib_gui.update_tags(elem, updates.tags)
  end

  -- TODO: This could be a lot better
  if updates.actions then
    for event_name, payload in pairs(updates.actions) do
      flib_gui.set_action(elem, event_name, payload)
    end
  end

  local substructures
  local substructures_len = #updates
  if substructures_len > 0 then
    if updates.children or updates.tabs then
      error("Children or tab-and-content pairs must ALL be in the array portion, or a subtable. Not both at once!")
    end
    substructures = {}
    for i = 1, substructures_len do
      substructures[i] = updates[i]
      updates[i] = nil
    end
  else
    substructures = updates.children or updates.tabs
    updates.children = nil
    updates.tabs = nil
  end
  local subelements
  if elem.type == "tabbed-pane" then
    subelements = elem.tabs
  else
    subelements = elem.children
  end

  if substructures then
    for i, substructure in pairs(substructures) do
      if substructure.tab or substructure.content then
        local elem_tab_and_content = subelements[i]
        if elem_tab_and_content then
          local tab = elem_tab_and_content.tab
          local tab_updates = substructures.tab
          if tab and tab_updates then
            recursive_update(tab, tab_updates)
          end
          local content = elem_tab_and_content.content
          local content_updates = substructures.content
          if content and content_updates then
            recursive_update(content, content_updates)
          end
        end
      elseif subelements[i] then
        recursive_update(subelements[i], substructure)
      end
    end
  end

  if updates.children then
    for i, child_updates in ipairs(updates.children) do
      if elem_children[i] then
        recursive_update(elem_children[i], child_updates)
      end
    end
  end
end

--- Update an existing GUI based on a given structure.
-- @tparam LuaGuiElement elem The element to update.
-- @tparam GuiUpdateStructure updates The updates to perform.
function flib_gui.update(elem, updates)
  recursive_update(elem, updates)
end

-- TAGS FUNCTIONS

--- Retrieve a GUI element's tags.
-- These tags are automatically written to and read from a subtable keyed by mod name, preventing conflicts.
--
-- If no tags exist, this function will return an empty table.
-- @tparam LuaGuiElement elem
-- @treturn table
function flib_gui.get_tags(elem)
  return elem.tags[mod_name] or {}
end

--- Set (override) a GUI element's tags.
-- These tags are automatically written to and read from a subtable keyed by mod name, preventing conflicts.
-- @tparam LuaGuiElement elem
-- @tparam table tags
function flib_gui.set_tags(elem, tags)
  local elem_tags = elem.tags
  elem_tags[mod_name] = tags
  elem.tags = elem_tags
end

--- Delete a GUI element's tags.
-- These tags are automatically written to and read from a subtable keyed by mod name, preventing conflicts.
--
-- @tparam LuaGuiElement elem
function flib_gui.delete_tags(elem)
  local elem_tags = elem.tags
  elem_tags[mod_name] = nil
  elem.tags = elem_tags
end

--- Perform a shallow merge on a GUI element's tags.
-- These tags are automatically written to and read from a subtable keyed by mod name, preventing conflicts.
--
-- Only the top level will be updated. If deep updating is needed, use @{gui.get_tags} and @{table.deep_merge},
-- then @{gui.set_tags}.
--
-- @tparam LuaGuiElement elem
-- @tparam table updates
function flib_gui.update_tags(elem, updates)
  local elem_tags = elem.tags
  local existing = elem_tags[mod_name]

  if not existing then
    existing = {}
    elem_tags[mod_name] = existing
  end

  for k, v in pairs(updates) do
    existing[k] = v
  end

  elem.tags = elem_tags
end

--- Set (overwrite) the specified action message for this GUI element.
--  @tparam LuaGuiElement elem
--  @tparam string event_name The GUI event name for this action, with the `_gui` portion omitted (i.e. `on_click`).
--  @tparam any|nil msg The action message, or `nil` to clear the action.
function flib_gui.set_action(elem, event_name, msg)
  local elem_tags = elem.tags
  local existing = elem_tags[mod_name]

  if not existing then
    existing = {}
    elem_tags[mod_name] = existing
  end

  local actions = existing.flib
  if not actions then
    actions = {}
    existing.flib = actions
  end

  actions[event_name] = msg

  elem.tags = elem_tags
end

--- Retrieve the specified action message for this GUI element.
-- @tparam LuaGuiElement elem
-- @tparam string event_name The GUI event name to get the action message for, with the `_gui` portion omitted (i.e.
-- `on_click`).
-- @treturn any|nil msg The action message, if there is one.
function flib_gui.get_action(elem, event_name)
  local elem_tags = elem.tags
  local existing = elem_tags[mod_name]

  if not existing then return end

  local actions = existing.flib
  if not actions then return end

  return actions[event_name]
end

--- Concepts
-- @section

--- A series of nested tables used to build a GUI.
-- This is an extension of @{LuaGuiElement}, providing new features and options.
--
-- This inherits all required properties from its base @{LuaGuiElement}, i.e. if the `type` field is
-- `sprite-button`, the @{GuiBuildStructure} must contain all the fields that a `sprite-button` @{LuaGuiElement}
-- requires.
--
-- There are a number of new fields that can be applied to a @{GuiBuildStructure} depending on the type:
--
-- @tparam[opt] table style_mods A key -> value dictionary defining modifications to make to the element's style.
-- Available properties are listed in @{LuaStyle}.
-- @tparam[opt] table elem_mods A key -> value dictionary defining modifications to make to the element. Available
-- properties are listed in @{LuaGuiElement}.
-- @tparam[opt] GuiElementActions actions Actions to take on certain GUI events.
-- @tparam[opt] string[] ref A nested table path in which to place a reference to this @{LuaGuiElement} in the output of
-- @{gui.build}.
-- @tparam[opt] GuiBuildStructure[] children @{GuiBuildStructure}s to add as children of this @{LuaGuiElement}.
-- Children may alternatively be defined in the array portion of the parent structure to remove a level of nesting.
-- @tparam[opt] TabAndContent[] tabs @{TabAndContent}s to add as tabs of this @{LuaGuiElement}. Tabs may alternatively
-- be defined int he array portion of the parent structure to remove a level of nesting.
-- @usage
-- gui.build(player.gui.screen, {
--   {
--     type = "frame",
--     direction = "vertical",
--     ref  =  {"window"},
--     actions = {
--       on_closed = {gui = "demo", action = "close"}
--     },
--     -- Titlebar
--     {type = "flow", ref = {"titlebar", "flow"},
--       {type = "label", style = "frame_title", caption = "Menu", ignored_by_interaction = true},
--       {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
--       {
--         type = "sprite-button",
--         style = "frame_action_button",
--         sprite = "utility/close_white",
--         hovered_sprite = "utility/close_black",
--         clicked_sprite = "utility/close_black",
--         ref = {"titlebar", "close_button"},
--         actions = {
--           on_click = {gui = "demo", action = "close"}
--         }
--       }
--     },
--     -- Content
--     {type = "frame", style = "inside_deep_frame_for_tabs",
--       {type = "tabbed-pane",
--         {
--           tab = {type = "tab", caption = "1"},
--           content = {type = "table", style = "slot_table", column_count = 10, ref = {"tables", 1}}
--         },
--         {
--           tab = {type = "tab", caption = "2"},
--           content = {type = "table", style = "slot_table", column_count = 10, ref = {"tables", 2}}
--         }
--       }
--     }
--   }
-- })
-- @Concept GuiBuildStructure

--- A series of nested tables used to update a GUI.
-- @tparam[opt] function cb A callback to run on this GUI element. The callback will be passed a @{LuaGuiElement} as its
-- first parameter.
-- @tparam[opt] string style The new style that the element should use.
-- @tparam[opt] table style_mods A key -> value dictionary defining modifications to make to the element's style.
-- Available properties are listed in @{LuaStyle}.
-- @tparam[opt] table elem_mods A key –> value dictionary defining modifications to make to the element. Available
-- properties are listed in LuaGuiElement.
-- @tparam table tags Tags that should be added to the element. This is identical to calling @{gui.update_tags} on the
-- element.
-- @tparam table actions Actions that should be added to the element. The format is identical to `actions` in a
-- @{GuiBuildStructure}. This is identical to calling `set_action` for each action on this element.
-- @tparam[opt] GuiUpdateStructure[] children @{GuiUpdateStructure}s to apply to the children of this @{LuaGuiElement}.
-- This may alternatively be defined in the array portion of the parent structure to improve readability.
-- @tparam[opt] TabAndContent[] tabs @{TabAndContent}s to apply to the tabs of this @{LuaGuiElement}. This may
-- alternatively be defined in the array portion of the parent structure to improve readability.
-- @usage
-- gui.update(
--   my_frame,
--   {
--     elem_mods = {caption = "Hello there!"},
--     tags = {subject = "General Kenobi"},
--     actions = {on_click = "everybody_say_hey"},
--     {
--      {
--        {tab = {elem_mods = {badge_text = "69"}}, content = {...}},
--        {content = {...}}
--      }
--     }
--   }
-- )
-- @Concept GuiUpdateStructure

--- A mapping of GUI event name -> action message.
-- Each key is a GUI event name (`on_gui_click`, `on_gui_elem_changed`, etc.) with the `_gui` part removed. For example,
-- `on_gui_click` will become `on_click`.
--
-- Each value is a custom set of data that @{gui.read_action} will return when that GUI event is fired and passes
-- this GUI element. This data may be of any type, as long as it is truthy.
--
-- Actions are kept under a `flib` subtable in the element's mod-specific tags subtable, retrievable with
-- @{gui.get_tags}. Because of this, there is no chance of accidental mod action overlaps, so feel free to use
-- generic actions such as "close" or "open".
--
-- A common format for a mod with multiple GUIs might be to give each GUI a name, and write the actions as shown below.
-- @usage
-- gui.build(player.gui.screen, {
--   {
--     type = "frame",
--     caption = "My frame",
--     actions = {
--       on_click = {gui = "my_gui", action = "handle_click"},
--       on_closed = {gui = "my_gui", action = "close"}
--     }
--   }
-- })
-- @Concept GuiElementActions

--- A table representing a tab <-> content pair.
-- When used in @{gui.build}, both fields are required. When used in @{gui.update}, both fields are optional.
-- @tfield GuiBuildStructure|GuiUpdateStructure tab Must be of type `tab`.
-- @tfield GuiBuildStructure|GuiUpdateStructure content
-- @Concept TabAndContent

-- @endsection

return flib_gui
