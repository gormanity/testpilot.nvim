# testpilot.nvim

A manually-triggered test file navigator for Neovim.

## Scope

Open the corresponding test file for the current source file. Starting with Go,
designed for extensibility to other languages.

## Architecture

```
lua/testpilot/
  init.lua           - setup(), open_test_file(), open_test_function() API
  config.lua         - Default options, apply/reset
  resolver.lua       - Dispatches to language modules by extension
  navigator.lua      - Opens first readable candidate test file
  treesitter.lua     - Extracts function name at cursor via Treesitter
  languages/
    go.lua           - Go test candidate + function mapping logic
    python.lua       - Python test candidate logic
    typescript.lua   - TypeScript/JS test candidate logic
    rust.lua         - Rust test candidate logic
    lua.lua          - Lua test candidate logic
```

## API

```lua
local testpilot = require("testpilot")
testpilot.setup({ open_method = "vsplit", notify = true })
testpilot.open_test_file()           -- returns boolean
testpilot.open_test_function()  -- returns boolean (requires Treesitter)

-- User adds their own keybindings:
vim.keymap.set("n", "<leader>tt", testpilot.open_test_file, { desc = "Open test file" })
vim.keymap.set("n", "<leader>tf", testpilot.open_test_function, { desc = "Jump to test function" })
```

## Design Decisions

- **Stateless**: No internal state tracking needed
- **No keymap registration**: Plugin exposes functions only, users bind them
- **Language dispatch**: `languages/<lang>.lua` exports
  `candidates(path, filename)` returning a list of candidate test file paths
- **Extensible**: Add a new language by creating one file in `languages/` and
  adding one entry in `resolver.lua`'s extension map
- **Function-level navigation**: `resolve_function()` dispatches to language
  modules that export `test_function_pattern()` for cursor-to-test-function
  jumping
- **Treesitter integration**: `treesitter.lua` walks the AST to find the
  enclosing function at cursor

## Configuration Defaults

```lua
{
  open_method = "vsplit",  -- how to open test files: "vsplit", "split", "edit", "tabedit"
  notify = true,           -- show notifications on success/failure
}
```
