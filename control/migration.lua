--- @module control.migration
local migration = {}

local string_split = require("__core__.lualib.util").split
local string_match = string.match
local string_format = string.format

function migration.compare_versions(v1, v2)
  local v1_split = string_split(v1, ".")
  local v2_split = string_split(v2, ".")
  for i=1,#v1_split do
    if v1_split[i] < v2_split[i] then
      return true
    elseif v1_split[i] > v2_split[i] then
      return false
    end
  end
  return false
end

--- normalizes version strings for easy comparison
---@param version string
---@param format string | nil defaults to "%02d.%02d.%02d"
---@return string | nil
---@usage ("__flib__.control.migration").format_version("1.10.1234", "%02d.%02d.%04d")
local default_version_format = "%02d.%02d.%02d"
local version_pattern = "(%d+).(%d+).(%d+)"
function migration.format_version(version, format)
  if version then
    format = format or default_version_format
    return string_format(format, string_match(version, version_pattern))
  end
  return nil
end

--- checks if normalized strings of current_version > old_version
---@param old_version string
---@param current_version string
---@param format string | nil defaults to "%02d.%02d.%02d"
---@return bool | nil
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

function migration.run(old, migrations, ...)
  local migrate = false
  for v,f in pairs(migrations) do
    if migrate or migration.compare_versions(old, v) then
      migrate = true
      f(...)
    end
  end
end

function migration.on_config_changed(e, migrations, ...)
  local changes = e.mod_changes[script.mod_name]
  if changes then
    local old = changes.old_version
    if old then
      migration.run(old, migrations, ...)
    else
      return false -- don't do generic migrations, because we just initialized
    end
  end
  return true
end

return migration