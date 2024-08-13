if ... ~= "__flib__.gui-lite" then
  return require("__flib__.gui-lite")
end

--- Utilities for building GUIs and handling GUI events.
--- ```lua
--- local flib_gui = require("__flib__.gui-lite")
--- ```
--- @class flib_gui
local flib_gui = {}

local handler_tag_key = "__" .. script.mod_name .. "_handler"

--- @type table<GuiElemHandler, string>
local handlers = {}
--- @type table<string, GuiElemHandler>
local handlers_lookup = {}

--- Add a new child or children to the given GUI element.
--- @param parent LuaGuiElement
--- @param def GuiElemDef|GuiElemDef[] The element definition, or an array of element definitions.
--- @param elems table<string, LuaGuiElement>? Optional initial `elems` table.
--- @return table<string, LuaGuiElement> elems Elements with names will be collected into this table.
--- @return LuaGuiElement first The element that was created first;  the "top level" element.
function flib_gui.add(parent, def, elems)
  if not parent or not parent.valid then
    error("Parent element is missing or invalid")
  end
  if not elems then
    elems = {}
  end
  -- If a single def was passed, wrap it in an array
  if def.type or (def.tab and def.content) then
    def = { def }
  end
  local first
  for i = 1, #def do
    local def = def[i]
    if def.type then
      -- Remove custom attributes from the def so the game doesn't serialize them
      local children = def.children
      local elem_mods = def.elem_mods
      local handler = def.handler
      local style_mods = def.style_mods
      local drag_target = def.drag_target
      -- If children were defined in the array portion, remove and collect them
      local has_array_children = false
      if def[1] then
        if children then
          error("Cannot define children in array portion and subtable simultaneously")
        end
        has_array_children = true
        children = {}
        for i = 1, #def do
          children[i] = def[i]
          def[i] = nil
        end
      end
      def.children = nil
      def.elem_mods = nil
      def.handler = nil
      def.style_mods = nil
      def.drag_target = nil

      local elem = parent.add(def)

      if not first then
        first = elem
      end
      if def.name then
        elems[def.name] = elem
      end
      if style_mods then
        for key, value in pairs(style_mods) do
          elem.style[key] = value
        end
      end
      if elem_mods then
        for key, value in pairs(elem_mods) do
          elem[key] = value
        end
      end
      if drag_target then
        local target = elems[drag_target]
        if not target then
          error("Drag target '" .. drag_target .. "' not found.")
        end
        elem.drag_target = target
      end
      if handler then
        local out
        if type(handler) == "table" then
          out = {}
          for name, handler in pairs(handler) do
            out[tostring(name)] = handlers[handler]
          end
        else
          out = handlers[handler]
        end
        local tags = elem.tags
        tags[handler_tag_key] = out
        elem.tags = tags
      end
      if children then
        flib_gui.add(elem, children, elems)
      end

      -- Re-add custom attributes
      if children and has_array_children then
        for i = 1, #children do
          def[i] = children[i]
        end
      else
        def.children = children
      end
      def.elem_mods = elem_mods
      def.handler = handler
      def.style_mods = style_mods
      def.drag_target = drag_target
    elseif def.tab and def.content then
      local _, tab = flib_gui.add(parent, def.tab, elems)
      local _, content = flib_gui.add(parent, def.content, elems)
      parent.add_tab(tab, content)
    end
  end
  return elems, first
end

--- Add the given handler functions to the registry for use with `flib_gui.add`. Each handler must have a unique name. If a
--- `wrapper` function is provided, it will be called instead, and will receive the event data and handler. The wrapper
--- can be used to execute logic or gather data common to all handler functions for this GUI.
--- @param new_handlers table<string, fun(e: GuiEventData)>
--- @param wrapper fun(e: GuiEventData, handler: function)?
--- @param prefix string?
function flib_gui.add_handlers(new_handlers, wrapper, prefix)
  for name, handler in pairs(new_handlers) do
    if prefix then
      name = prefix .. "/" .. name
    end
    if type(handler) == "function" then
      if handlers_lookup[name] then
        error("Attempted to register two GUI event handlers with the same name: " .. name)
      end
      handlers[handler] = name
      if wrapper then
        handlers_lookup[name] = function(e)
          wrapper(e, handler)
        end
      else
        handlers_lookup[name] = handler
      end
    end
  end
end

--- Dispatch the handler associated with this event and GUI element. The handler must have been added using
--- `flib_gui.add_handlers`.
--- @param e GuiEventData
--- @return boolean handled True if an event handler was called.
function flib_gui.dispatch(e)
  local elem = e.element
  if not elem then
    return false
  end
  local tags = elem.tags --[[@as Tags]]
  local handler_def = tags[handler_tag_key]
  if not handler_def then
    return false
  end
  local handler_type = type(handler_def)
  if handler_type == "table" then
    handler_def = handler_def[tostring(e.name)]
  end
  if handler_def then
    local handler = handlers_lookup[handler_def]
    if handler then
      handler(e)
      return true
    end
  end
  return false
end

--- For use with `__core__/lualib/event_handler`. Pass `flib_gui` into `handler.add_lib` to handle
--- all GUI events automatically.
flib_gui.events = {}
for name, id in pairs(defines.events) do
  if string.find(name, "on_gui_") then
    flib_gui.events[id] = flib_gui.dispatch
  end
end

--- Handle all GUI events with `flib_gui.dispatch`. Will not overwrite any existing event handlers.
function flib_gui.handle_events()
  for id in pairs(flib_gui.events) do
    if not script.get_event_handler(id) then
      script.on_event(id, flib_gui.dispatch)
    end
  end
end

--- Format the given handlers for use in a GUI element's tags. An alternative to using `flib_gui.add` if event handling
--- is the only desired feature.
---
--- ### Example
---
--- ```lua
--- --- @param e EventData.on_gui_click
--- local function on_button_clicked(e)
---   game.print("You clicked it!")
--- end
---
--- player.gui.screen.add({
---   type = "button",
---   caption = "Click me!",
---   tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = on_button_clicked }),
--- })
---
--- flib_gui.handle_events({ on_button_clicked = on_button_clicked })
--- ```
--- @param input GuiElemHandler|table<defines.events, GuiElemHandler?>
--- @param existing Tags?
--- @return Tags
function flib_gui.format_handlers(input, existing)
  local out
  if type(input) == "table" then
    out = {}
    for name, handler in pairs(input) do
      out[tostring(name)] = handlers[handler]
    end
  else
    out = handlers[input]
  end
  if existing then
    existing[handler_tag_key] = out
    return existing
  end
  return { [handler_tag_key] = out }
end

--- A GUI element definition. This extends `LuaGuiElement.add_param` with several new attributes.
--- Children may be defined in the array portion as an alternative to the `children` subtable.
--- @class GuiElemDef: LuaGuiElement.add_param.button|LuaGuiElement.add_param.camera|LuaGuiElement.add_param.checkbox|LuaGuiElement.add_param.choose_elem_button|LuaGuiElement.add_param.drop_down|LuaGuiElement.add_param.flow|LuaGuiElement.add_param.frame|LuaGuiElement.add_param.line|LuaGuiElement.add_param.list_box|LuaGuiElement.add_param.minimap|LuaGuiElement.add_param.progressbar|LuaGuiElement.add_param.radiobutton|LuaGuiElement.add_param.scroll_pane|LuaGuiElement.add_param.slider|LuaGuiElement.add_param.sprite|LuaGuiElement.add_param.sprite_button|LuaGuiElement.add_param.switch|LuaGuiElement.add_param.tab|LuaGuiElement.add_param.table|LuaGuiElement.add_param.text_box|LuaGuiElement.add_param.textfield
--- @field style_mods LuaStyle? Modifications to make to the element's style.
--- @field elem_mods LuaGuiElement? Modifications to make to the element itself.
--- @field drag_target string? Set the element's drag target to the element whose name matches this string. The drag target must be present in the `elems` table.
--- @field handler (GuiElemHandler|table<defines.events, GuiElemHandler>)? Handler(s) to assign to this element. If assigned to a function, that function will be called for any GUI event on this element.
--- @field children GuiElemDef[]? Children to add to this element.
--- @field tab GuiElemDef? To add a tab, specify `tab` and `content` and leave all other fields unset.
--- @field content GuiElemDef? To add a tab, specify `tab` and `content` and leave all other fields unset.

--- A handler function to invoke when receiving GUI events for this element.
--- @alias GuiElemHandler fun(e: GuiEventData)

--- Aggregate type of all possible GUI events.
--- @alias GuiEventData EventData.on_gui_checked_state_changed|EventData.on_gui_click|EventData.on_gui_closed|EventData.on_gui_confirmed|EventData.on_gui_elem_changed|EventData.on_gui_location_changed|EventData.on_gui_opened|EventData.on_gui_selected_tab_changed|EventData.on_gui_selection_state_changed|EventData.on_gui_switch_state_changed|EventData.on_gui_text_changed|EventData.on_gui_value_changed

return flib_gui
