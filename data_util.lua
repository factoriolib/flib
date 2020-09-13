local str = "FLIB DEPRECATION WARNING: data_util was renamed to data-util in v0.3.1. Please update your require paths. The old path will cease to work when Factorio 1.1 is released."
if __DebugAdapter then
  __DebugAdapter.breakpoint(str)
else
  log(str)
end
return require("__flib__.data-util")