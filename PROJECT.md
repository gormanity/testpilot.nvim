# testpilot.nvim

A manually-triggered test file navigator for Neovim.

## Scope

Open the corresponding test file for the current source file. Starting with Go, designed for extensibility to other languages.

## Architecture

```
lua/testpilot/
  init.lua           - setup(), open_test() API
  config.lua         - Default options, apply/reset
  resolver.lua       - Dispatches to language modules by extension
  navigator.lua      - Opens first readable candidate test file
  languages/
    go.lua           - Go test candidate logic
```

## API

```lua
local testpilot = require("testpilot")
testpilot.setup({ open_method = "vsplit", notify = true })
testpilot.open_test()  -- returns boolean

-- User adds their own keybinding:
vim.keymap.set("n", "<leader>tt", testpilot.open_test, { desc = "Open test file" })
```

## Design Decisions

- **Stateless**: No internal state tracking needed
- **No keymap registration**: Plugin exposes functions only, users bind them
- **Language dispatch**: `languages/<lang>.lua` exports `candidates(path, filename)` returning a list of candidate test file paths
- **Extensible**: Add a new language by creating one file in `languages/` and adding one entry in `resolver.lua`'s extension map
- **Function-level ready**: Resolver can later gain `resolve_function()`, language modules can add `function_candidates()`

## Configuration Defaults

```lua
{
  open_method = "vsplit",  -- how to open test files: "vsplit", "split", "edit", "tabedit"
  notify = true,           -- show notifications on success/failure
}
```
