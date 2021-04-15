local inner_separator = "⤬"
local separator = "⤬⤬⤬"

local translation = {}

function translation.new(dictionary_name)
  local initial = {"", "FLIB_TRANSLATION_DICTIONARY", inner_separator, dictionary_name, separator}
  initial._ref = initial

  return initial
end

function translation.add(dictionary, key, value)
  local obj = {"", key, inner_separator, value, separator}
  dictionary._ref[6] = obj
  dictionary._ref = obj
end

function translation.split_results(e, include_failed)
  if e.translated then
    local _, _, dict_name, translation = string.find(
      e.result,
      "FLIB_TRANSLATION_DICTIONARY"..inner_separator.."(.-)"..separator.."(.*)$"
    )
    if dict_name and translation then
      local dictionary = {}
      for str in string.gmatch(translation, "(.-)"..separator) do
        local _, _, key, value = string.find(str, "^(.-)"..inner_separator.."(.-)$")
        if key and (include_failed or not string.find(value, "^Unknown key: ")) then
          dictionary[key] = value
        end
      end
      return dict_name, dictionary
    end
  else
    game.write_file("flib/helpful_info.log", serpent.block(e))
    error(
      [[
        Flib bulk translation failed. Helpful information has been written to the script-output/flib directory.
        Please contact raiguard and upload that information.
      ]]
    )
  end
end

return translation
