data:extend{
  {
    type = "int-setting",
    name = "flib-dictionary-levels-per-batch",
    setting_type = "runtime-global",
    default_value = 15,
    minimum_value = 1,
    maximum_value = 15,
  },
  {
    type = "int-setting",
    name = "flib-translations-per-tick",
    setting_type = "runtime-global",
    default_value = 50,
    minimum_value = 1,
    hidden = true,
  },
}
