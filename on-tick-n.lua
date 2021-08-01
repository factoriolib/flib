local on_tick_n = {}

function on_tick_n.init()
  if not global.__flib then
    global.__flib = {}
  end
  global.__flib.on_tick_n = {}
end

function on_tick_n.retrieve(tick)
  -- Failsafe for rare cases where on_tick can fire before on_init
  if not global.__flib or not global.__flib.on_tick_n then return end
  local actions = global.__flib.on_tick_n[tick]
  if actions then
    global.__flib.on_tick_n[tick] = nil
    return actions
  end
end

function on_tick_n.add(tick, action)
  local list = global.__flib.on_tick_n
  local tick_list = list[tick]
  if tick_list then
    local index = #tick_list + 1
    tick_list[index] = action
    return {index = index, tick = tick}
  else
    list[tick] = {action}
    return {index = 1, tick = tick}
  end
end

function on_tick_n.remove(ident)
  local tick_list = global.__flib.on_tick_n[ident.tick]
  if not tick_list or not tick_list[ident.index] then return false end

  tick_list[ident.index] = nil

  return true
end

return on_tick_n
