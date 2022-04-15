To run tests with vscode test explorer or lua.

Adds package.searcher for `__modname__` requires.
Adds some package.path(s) because path explosion will make it find the correct file.
This framework sets up the following.
Adds generic versions of global factorio functions  (defines, log, table_size).

Test Explorer extension,  search for tests, run tests (optionally debug tests)
Code Runner (.run) extension, just run the file
Sumneko vscode: run/debug should work.
Lua: From the mod root run `lua tests/test_name.lua`
