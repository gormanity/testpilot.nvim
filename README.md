<p align="center">
  <img src="assets/icon.svg" width="200" alt="testpilot.nvim icon"/>
</p>

# testpilot.nvim

Navigate from source code to test code in Neovim. Jump to the test file for your
current buffer, or jump directly to the test function for the function under
your cursor.

## Features

- Jump to the corresponding **test file** from any source file
- Jump to the corresponding **test function** using Treesitter (e.g., cursor on
  `HandleRequest` → jumps to `TestHandleRequest`)
- Open tests in splits, tabs, or the current window
- Supports Go, Python, TypeScript/JS, Rust, and Lua

## Requirements

- Neovim >= 0.9
- A Treesitter parser for your language (only needed for `open_test_function`)

## Installation and Setup

Install with your package manager, then call `setup()` and add keybindings.
testpilot.nvim does not register any keybindings by default — you choose how to
trigger it.

### lazy.nvim

```lua
{
  "jmgorman/testpilot.nvim",
  config = function()
    require("testpilot").setup()

    vim.keymap.set("n", "<leader>tt",
      require("testpilot").open_test_file,
      { desc = "Open test file" })

    vim.keymap.set("n", "<leader>tf",
      require("testpilot").open_test_function,
      { desc = "Jump to test function" })
  end,
}
```

## Configuration

All options shown below are defaults. You only need to pass the values you want
to change:

```lua
require("testpilot").setup({
  open_method = "vsplit",     -- how to open the test file: "vsplit", "split", "edit", "tabedit"
  notify = "failures",       -- "all", "failures", or "none"
})
```

You can also override `open_method` per keybinding:

```lua
vim.keymap.set("n", "<leader>ts", function()
  require("testpilot").open_test_file({ open_method = "split" })
end, { desc = "Open test in split" })
```

## API

testpilot.nvim exposes two functions that you use in your keybindings:

| Function                    | Description                                                                      |
| --------------------------- | -------------------------------------------------------------------------------- |
| `open_test_file(opts?)`     | Open the test file for the current buffer                                        |
| `open_test_function(opts?)` | Open the test file and jump to the test function at cursor (requires Treesitter) |

Both return `true` on success and `false` on failure. The optional `opts` table
accepts `open_method` to override the configured default for that call.

## Supported Languages

Each language defines how source files map to test files. Languages with
function navigation also map source function names to test function names,
enabling `open_test_function()` to jump to the right location.

| Language      | Source Pattern    | Test Pattern              | Function Navigation |
| ------------- | ----------------- | ------------------------- | ------------------- |
| Go            | `*.go`            | `*_test.go`               | `Foo` → `TestFoo`   |
| Python        | `*.py`            | `test_*.py`, `*_test.py`  |                     |
| TypeScript/JS | `*.ts/tsx/js/jsx` | `*.test.*`, `*.spec.*`    |                     |
| Rust          | `*.rs`            | `*_test.rs`, `tests/*.rs` |                     |
| Lua           | `*.lua`           | `*_spec.lua`              |                     |

## Contributing

### Adding a New Language

1. Create `lua/testpilot/languages/<lang>.lua`
2. Export `candidates(path, filename)` — returns a list of candidate test file
   paths
3. Optionally export `test_function_name(func_name)` and
   `test_function_pattern(func_name)` for function-level navigation
4. Add the file extension mapping in `lua/testpilot/resolver.lua`
5. Add tests in `tests/testpilot/resolver_spec.lua`

### Running Tests

```bash
make test
```

Requires [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).
