To run tests with vscode test explorer or lua.

clone https://github.com/Nexela/faketorio.git as `faketorio` in either flib/tests(symlink ok)  or anywhere you feel like.
  if you cloned it into `flib/tests/` then no further action is needed
  if you cloned it anyhere else create `tests/faketorio_path.lua` with the contents
  ```lua
  return '/absolute/path/to/faketorio/init.lua
  ```

Some things faketorio does
Adds path to lualib (via faketorio/lualib)  allows core lualib files like `require('util')` to find lualib/util.lua
Adds some other package.path(s) because path explosion will make it find the correct file
Adds package.searcher for `__modname__` requires.
Adds generic versions of global factorio functions  (defines, serpent, log, table_size)

Test Explorer extension,  search for tests, run tests (optionally debug tests)
Code Runner (.run) extension, just run the file
Sumneko vscode: run/debug should work.
Lua: From the mod root run `lua tests/test_name.lua`
