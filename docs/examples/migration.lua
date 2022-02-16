local event = require("__flib__.event")
local migration = require("__flib__.migration")

-- the migrations table - this will probably go into its own file
local migrations = {
  -- each function will be run when upgrading from a version older than it
  -- for example, if we were upgraing from 1.0.3 to 1.1.0, the last two functions would run, but not the first
  ["1.0.3"] = function()
    -- logic specific to changes made in 1.0.3
  end,
  ["1.0.4"] = function()
    -- logic specific to changes made in 1.0.4
  end,
  ["1.1.0"] = function()
    -- logic specific to changes made in 1.1.0
  end,
}

event.on_configuration_changed(function(e)
  -- `on_config_changed` will check the event data and apply any migrations in the migrations table that need to be
  if migration.on_config_changed(e, migrations) then
    -- if the result is true, perform "generic migrations", i.e. refreshing a GUI with the latest item prototypes
    -- this chunk will run on every call *except* for right after `on_init`, where the other chunk will run instead
  end
  -- if the result is false, that means that this mod was just added, so migrations shouldn't be performed
  -- if you have code that absolutely must run despite this, put it here
end)
