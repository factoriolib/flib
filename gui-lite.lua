local flib_event = require("__flib__.event")

local handler_tag_key = script.mod_name .. "_handler"

--- `gui-lite` is a slimmer and more convenient GUI library.
local flib_gui = {}

--- @type table<GuiElemHandler, string>
local handlers = {}
--- @type table<string, GuiElemHandler>
local handlers_lookup = {}

--- Add new children to the given GUI element.
--- @param parent LuaGuiElement
--- @param defs GuiElemDef[]
--- @param elems table<string, LuaGuiElement>? Elems table to use; a new table will be created if this is not specified.
--- @return table<string, LuaGuiElement> elems Elements with names will be collected into this table.
function flib_gui.add(parent, defs, elems)
  if not elems then
    elems = {}
  end
  for i = 1, #defs do
    local def = defs[i]
    if def.type then
      -- Remove custom attributes from the def so the game doesn't serialize them
      local children = def.children
      local elem_mods = def.elem_mods
      local handler = def.handler
      local style_mods = def.style_mods
      def.children = nil
      def.elem_mods = nil
      def.handler = nil
      def.style_mods = nil
      -- If children were defined in the array portion, remove and collect them
      if def[1] then
        if children then
          error("Cannot define children in array portion and subtable simultaneously")
        end
        children = {}
        for i = 1, #def do
          children[i] = def[i]
          def[i] = nil
        end
      end

      local elem = parent.add(def)

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
      if handler then
        local out
        if type(handler) == "table" then
          out = {}
          for name, handler in pairs(handler) do
            out[name] = handlers[handler]
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
      def.children = children -- FIXME: Array portion
      def.elem_mods = elem_mods
      def.handler = handler
      def.style_mods = style_mods
    elseif def.tab and def.content then
      flib_gui.add(parent, def.tab, elems)
      flib_gui.add(parent, def.content, elems)
      local children = parent.children
      parent.add_tab(children[#children - 1], children[#children])
    end
  end
  return elems
end

--- Add the given handler functions to the registry.
--- @param new_handlers table<string, fun(e: GuiEventData)>
function flib_gui.add_handlers(new_handlers)
  for name, handler in pairs(new_handlers) do
    if type(handler) == "function" then
      if handlers_lookup[name] then
        error("Attempted to register two GUI event handlers with the same name: " .. name)
      end
      handlers[handler] = name
      handlers_lookup[name] = handler
    end
  end
end

--- Dispatch the handler associated with this event, if any.
--- @param e GuiEventData
--- @return boolean handled True if an event handler was called.
function flib_gui.dispatch(e)
  local elem = e.element
  if not elem then
    return false
  end
  local tags = elem.tags
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
      if flib_gui.dispatch_wrapper then
        flib_gui.dispatch_wrapper(e, handler)
      else
        handler(e)
      end
      return true
    end
  end
  return false
end

--- If defined, `gui.dispatch` will call this function instead of the handler function.
--- Intended use is to assemble common data that your handlers need.
--- @type fun(e: GuiEventData, handler: GuiElemHandler)?
flib_gui.dispatch_wrapper = nil

--- Handle all GUI events with `flib_gui.dispatch`.
function flib_gui.handle_events()
  for name, id in pairs(defines.events) do
    if string.find(name, "on_gui_") then
      flib_event.register(id, flib_gui.dispatch)
    end
  end
end

--- A GUI element definition. This extends `LuaGuiElement.add_param` with several new attributes.
--- Children may be defined in the array portion as an alternative to the `children` subtable.
--- @class GuiElemDef: LuaGuiElement.add_param
--- @field style_mods table? Modifications to make to the element's style
--- @field elem_mods table? Modifications to make to the element itself
--- @field handler GuiElemHandler? Handler(s) to assign to this element
--- @field children GuiElemDef[]? Children to add to this element
--- @field tab GuiElemDef? To add a tab, specify `tab` and `content` and leave all other fields unset.
--- @field content GuiElemDef? To add a tab, specify `tab` and `content` and leave all other fields unset.

--- A handler function to invoke when receiving GUI events for this element. Alternatively, handlers may be specified
--- for specific events.
--- @alias GuiElemHandler fun(e: GuiEventData)|table<defines.events, fun(e: GuiEventData)>

--- Aggregate type of all possible GUI events.
--- @alias GuiEventData  EventData.on_gui_checked_state_changed|EventData.on_gui_click|EventData.on_gui_closed|EventData.on_gui_confirmed|EventData.on_gui_elem_changed|EventData.on_gui_location_changed|EventData.on_gui_opened|EventData.on_gui_selected_tab_changed|EventData.on_gui_selection_state_changed|EventData.on_gui_switch_state_changed|EventData.on_gui_text_changed|EventData.on_gui_value_changed

return flib_gui
