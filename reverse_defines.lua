local str = "FLIB DEPRECATION WARNING: reverse_defines was renamed to reverse-defines in v0.3.1. Please update your require paths. The old path will cease to work when Factorio 1.1 is released."
if __DebugAdapter then
  __DebugAdapter.breakpoint(str)
else
  log(str)
end
return require("__flib__.reverse-defines")