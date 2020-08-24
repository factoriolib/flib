local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")

local mini_wiki = require("__flib__.scripts.mini-wiki.base")

event.on_init(function()
  gui.init()

  for i, player in pairs(game.players) do
    mini_wiki.init_player(i, player)
  end

  gui.build_lookup_tables()
end)

event.on_load(function()
  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, {}) then
    gui.check_filter_validity()
  end
end)

gui.register_handlers()