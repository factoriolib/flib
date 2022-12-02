--- A slim and convenient GUI library. See 'docs/examples/gui-lite.lua' for a usage demonstration.
--- @class flib_gui_lite
local flib_gui = {}

local handler_tag_key = "__" .. script.mod_name .. "_handler"

--- @type table<GuiElemHandler, string>
local handlers = {}
--- @type table<string, GuiElemHandler>
local handlers_lookup = {}

--- Add a new child or children to the given GUI element.
--- @param parent LuaGuiElement
--- @param def GuiElemDef Can have a single topmost element, or be an array of elements to add.
--- @param elems table<string, LuaGuiElement>? Elems table to use; a new table will be created if this is not specified.
--- @return table<string, LuaGuiElement> elems Elements with names will be collected into this table.
--- @return LuaGuiElement first The element that was created first.
function flib_gui.add(parent, def, elems)
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
      def.children = nil
      def.elem_mods = nil
      def.handler = nil
      def.style_mods = nil
      def.drag_target = nil
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
      def.children = children -- FIXME: Array portion
      def.elem_mods = elem_mods
      def.handler = handler
      def.style_mods = style_mods
    elseif def.tab and def.content then
      local _, tab = flib_gui.add(parent, def.tab, elems)
      local _, content = flib_gui.add(parent, def.content, elems)
      parent.add_tab(tab, content)
    end
  end
  return elems, first
end

--- Add the given handler functions to the registry.
--- @param new_handlers table<string, fun(e: GuiEventData)>
--- @param wrapper fun(e: GuiEventData, handler: function)? If specified, dispatch() will call this function instead
--- of directly calling the handler. Useful for gathering information or writing other boilerplate that all of the
--- @param prefix string? If provided, handler names will be prefixed with this value.
--- handlers need.
function flib_gui.add_handlers(new_handlers, wrapper, prefix)
  for name, handler in pairs(new_handlers) do
    if prefix then
      name = prefix .. ":" .. name
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

--- Dispatch the handler associated with this event, if any.
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

--- Handle all GUI events with `flib_gui.dispatch`. This will add handlers for all `on_gui_*` events. If you need to
--- have custom logic for a handler, create it after calling this function and call `flib_gui.dispatch` in that
--- function.
function flib_gui.handle_events()
  for name, id in pairs(defines.events) do
    if string.find(name, "on_gui_") then
      script.on_event(id, flib_gui.dispatch)
    end
  end
end

--- A GUI element definition. This extends `LuaGuiElement.add_param` with several new attributes.
--- Children may be defined in the array portion as an alternative to the `children` subtable.
--- @class GuiElemDefClass: LuaGuiElement.add_param
--- @field style_mods LuaStyle? Modifications to make to the element's style
--- @field elem_mods LuaGuiElement? Modifications to make to the element itself
--- @field drag_target string? Set the element's drag target to the element whose name matches this string. The drag target must be present in the `elems` table.
--- @field handler GuiElemHandler? Handler(s) to assign to this element
--- @field children GuiElemDef[]? Children to add to this element
--- @field tab GuiElemDef? To add a tab, specify `tab` and `content` and leave all other fields unset.
--- @field content GuiElemDef? To add a tab, specify `tab` and `content` and leave all other fields unset.

--- @alias GuiElemDef GuiElemDefClass|GuiElemDef[]

--- A handler function to invoke when receiving GUI events for this element. Alternatively, separate handlers may be
--- specified for different events.
--- @alias GuiElemHandler fun(e: GuiEventData)|table<defines.events, fun(e: GuiEventData)>

--- Aggregate type of all possible GUI events.
--- @alias GuiEventData  EventData.on_gui_checked_state_changed|EventData.on_gui_click|EventData.on_gui_closed|EventData.on_gui_confirmed|EventData.on_gui_elem_changed|EventData.on_gui_location_changed|EventData.on_gui_opened|EventData.on_gui_selected_tab_changed|EventData.on_gui_selection_state_changed|EventData.on_gui_switch_state_changed|EventData.on_gui_text_changed|EventData.on_gui_value_changed

return flib_gui
