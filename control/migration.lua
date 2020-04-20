---@module control.migration
---@usage local migration = require("__flib__.control.migration")
local migration = {}

local string_match = string.match
local string_format = string.format

---@section Functions

--- Normalizes version strings for easy comparison.
---@param version string
---@param format string | nil Defaults to "%02d.%02d.%02d"
---@return string | nil
---@usage migration.format_version("1.10.1234", "%02d.%02d.%04d")
local default_version_format = "%02d.%02d.%02d"
local version_pattern = "(%d+).(%d+).(%d+)"
function migration.format_version(version, format)
  if version then
    format = format or default_version_format
    return string_format(format, string_match(version, version_pattern))
  end
  return nil
end

--- Checks if normalized strings of current_version > old_version.
---@param old_version string
---@param current_version string
---@param format string | nil Defaults to "%02d.%02d.%02d"
---@return boolean | nil
function migration.is_new_version(old_version, current_version, format)
  local v1 = migration.format_version(old_version, format)
  local v2 = migration.format_version(current_version, format)
  if v1 and v2 then
    if v2 > v1 then
      return true
    end
    return false
  end
  return nil
end

--- Runs migrations against the given version.
---@param old_version string
---@param migrations MigrationsTable
---@param format string Defaults to "%02d.%02d.%02d"
function migration.run(old_version, migrations, format)
  local migrate = false
  for version, func in pairs(migrations) do
    if migrate or migration.is_new_version(old_version, version, format) then
      migrate = true
      func()
    end
  end
end

--- Determines if migrations need to be run for this mod, then runs them if needed.
---@param event_data ConfigurationChangedData
---@param migrations MigrationsTable
---@param[optional] mod_name string The mod to check against, defaults to the mod this is used in.
---@treturn boolean Whether or not to run generic migrations.
---@usage
-- -- In on_configuration_changed:
-- if migration.on_config_changed(e, migrations) then
--   -- run generic migrations
--   rebuild_prototype_data()
-- end
function migration.on_config_changed(event_data, migrations, mod_name)
  local changes = event_data.mod_changes[mod_name or script.mod_name]
  if changes then
    local old_version = changes.old_version
    if old_version then
      migration.run(old_version, migrations)
    else
      return false -- don't do generic migrations, because we just initialized
    end
  end
  return true
end

---@section Concepts

---@alias MigrationsTable table<string,function>
-- Array string -> function. Each string is a version number, and each value is a function that will be run for that version.
-- ```
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
-- ```

---@class ConfigurationChangedData https://lua-api.factorio.com/latest/Concepts.html#ConfigurationChangedData

return migration