# testpilot.nvim

A manually-triggered test file navigator for Neovim. Jump to the corresponding
test file for your current source file.

## Features

- Open test files in splits, tabs, or the current window
- Go language support (more languages planned)
- Extensible language resolver architecture

## Installation

### lazy.nvim

```lua
{
  "jmgorman/testpilot.nvim",
  config = function()
    require("testpilot").setup()
  end,
}
```

## Configuration

```lua
require("testpilot").setup({
  open_method = "vsplit",  -- "vsplit", "split", "edit", "tabedit"
  notify = true,           -- show notifications on success/failure
})
```

## API

```lua
local testpilot = require("testpilot")

-- Open the test file for the current buffer (uses configured open_method)
testpilot.open_test()  -- returns boolean

-- Override open_method per call
testpilot.open_test({ open_method = "split" })
```

## Keybindings

testpilot.nvim does not register any keybindings. Add your own:

```lua
vim.keymap.set("n", "<leader>tt",
  require("testpilot").open_test,
  { desc = "Open test file" })

-- Or with a specific open method per binding:
vim.keymap.set("n", "<leader>tv", function()
  require("testpilot").open_test({ open_method = "vsplit" })
end, { desc = "Open test in vsplit" })

vim.keymap.set("n", "<leader>ts", function()
  require("testpilot").open_test({ open_method = "split" })
end, { desc = "Open test in split" })
```

## Supported Languages

| Language | Source Pattern | Test Pattern |
| -------- | -------------- | ------------ |
| Go       | `*.go`         | `*_test.go`  |

## Adding Language Support

Create a new file in `lua/testpilot/languages/` that exports a
`candidates(path, filename)` function returning a list of candidate test file
paths. Then add the file extension mapping in `lua/testpilot/resolver.lua`.

## Running Tests

```bash
make test
```

Requires [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).
