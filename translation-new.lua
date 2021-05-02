local inner_separator = "⤬"
local separator = "⤬⤬⤬"

local translation = {}

function translation.new(dictionary_name, initial_contents)
  local initial = {"", "FLIB_TRANSLATION_DICTIONARY", inner_separator, dictionary_name, separator}
  initial._ref = initial

  for key, value in pairs(initial_contents or {}) do
    translation.add(initial, key, value)
  end

  return initial
end

function translation.add(dictionary, key, value)
  local obj = {"", key, inner_separator, value, separator}
  dictionary._ref[6] = obj
  dictionary._ref = obj
end

function translation.split_results(e, include_failed)
  if e.translated then
    local _, _, dict_name, result = string.find(
      e.result,
      "FLIB_TRANSLATION_DICTIONARY"..inner_separator.."(.-)"..separator.."(.*)$"
    )
    if dict_name and result then
      if type(include_failed) == "function" then
        include_failed = include_failed(dict_name)
      elseif include_failed == nil then
        include_failed = translation.include_failed_type.no
      end

      local dictionary = {}
      for str in string.gmatch(result, "(.-)"..separator) do
        local _, _, key, value = string.find(str, "^(.-)"..inner_separator.."(.-)$")
        if key then
          if string.find(value, "^Unknown key: ") then
            if include_failed == translation.include_failed_type.key then
              dictionary[key] = key
            elseif include_failed == translation.include_failed_type.yes then
              dictionary[key] = value
            end
          else
            dictionary[key] = value
          end
        end
      end
      return dict_name, dictionary
    end
  else
    game.write_file("flib/helpful_info.log", serpent.block(e))
    error(
      [[
        Flib bulk translation failed. Helpful information has been written to the script-output/flib directory.
        Please contact raiguard and provide that information.
      ]]
    )
  end
end

translation.include_failed_type = {
  no = 0,
  key = 1,
  yes = 2
}

return translation
