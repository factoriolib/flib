--- Mod migrations and version comparison functions.
-- @module migration
-- @alias flib_migration
-- @usage local migration = require("__flib__.migration")
local flib_migration = {}

local string = string
local table = table

local version_pattern = "%d+"
local version_format = "%02d"

--- Functions
-- @section

--- Normalize version strings for easy comparison.
-- @tparam string version
-- @tparam[opt="%02d"] string format
-- @treturn string|nil
-- @usage
-- migration.format_version("1.10.1234", "%04d")
-- migration.format_version("3", "%02d")
function flib_migration.format_version(version, format)
  if version then
    format = format or version_format
    local tbl = {}
    for v in string.gmatch(version, version_pattern) do
      tbl[#tbl+1] = string.format(format, v)
    end
    if next(tbl) then
      return table.concat(tbl, ".")
    end
  end
  return nil
end

--- Check if current_version is newer than old_version.
-- @tparam string old_version
-- @tparam string current_version
-- @tparam[opt=%02d] string format
-- @treturn boolean|nil
function flib_migration.is_newer_version(old_version, current_version, format)
  local v1 = flib_migration.format_version(old_version, format)
  local v2 = flib_migration.format_version(current_version, format)
  if v1 and v2 then
    if v2 > v1 then
      return true
    end
    return false
  end
  return nil
end

--- Run migrations against the given version.
-- @tparam string old_version
-- @tparam MigrationsTable migrations
-- @tparam[opt="%02d"] string format
function flib_migration.run(old_version, migrations, format)
  local migrate = false
  for version, func in pairs(migrations) do
    if migrate or flib_migration.is_newer_version(old_version, version, format) then
      migrate = true
      func()
    end
  end
end

--- Determine if migrations need to be run for this mod, then run them if needed.
-- @tparam Concepts.ConfigurationChangedData event_data
-- @tparam MigrationsTable migrations
-- @tparam[opt] string mod_name The mod to check against, defaults to the mod this is used in.
-- @treturn boolean If true, run generic migrations. If false, run post-init setup.
-- @usage
-- -- In on_configuration_changed:
-- if migration.on_config_changed(e, migrations) then
--   -- run generic (non-init) migrations
--   rebuild_prototype_data()
-- else
--   -- run post-init setup
--   unlock_recipes_for_cheating_forces()
-- end
function flib_migration.on_config_changed(event_data, migrations, mod_name)
  local changes = event_data.mod_changes[mod_name or script.mod_name]
  if changes then
    local old_version = changes.old_version
    if old_version then
      flib_migration.run(old_version, migrations)
    else
      return false -- don't do generic migrations, because we just initialized
    end
  end
  return true
end

return flib_migration

--- Concepts
-- @section

--- @Concept MigrationsTable
-- Dictionary string -> function. Each string is a version number, and each value is a
-- function that will be run for that version.
-- @tparam {[string]=function,...} ...
-- @usage
-- {
--   ["1.0.1"] = function()
--     global.foo = nil
--     for _, player_table in pairs(global.players) do
--       player_table.bar = "Lorem ipsum"
--     end
--   end,
--   ["1.1.0"] = function()
--     global.foo = "bar"
--   end
-- }