# Agent Guidelines for testpilot.nvim

## Coding Conventions

- Lua modules return a single table
- No global state; module-level locals only
- Functions that can fail return `(success, value_or_message)`
- Use `vim.notify()` for user-facing messages (level = vim.log.levels.INFO or
  WARN)
- Escape file paths with `vim.fn.fnameescape()` before passing to vim commands

## Running Tests

```bash
make test
```

Note: The Makefile uses `PlenaryBustedDirectory` with `minimal_init`, which is
required for `helpers.simulation` to resolve in child processes.
`PlenaryBustedFile` does NOT pass `minimal_init` to child processes and will
fail for tests that use helpers.

## Adding a New Language

1. Create `lua/testpilot/languages/<lang>.lua`
2. Export `candidates(path, filename)` → returns list of candidate test file
   paths
3. Optionally export `test_function_name(func_name)` and
   `test_function_pattern(func_name)` for function-level navigation
4. Add extension mapping in `lua/testpilot/resolver.lua` (`extension_map`)
5. Add tests in `tests/testpilot/resolver_spec.lua`

## jj Workflow

- One logical change per `jj` commit
- Use `jj describe -m "message"` to set commit messages
- Use `jj new` to start the next change
- Use `jj log` to review history

## Project Structure

```
lua/testpilot/          - Plugin source
tests/testpilot/        - Test specs (plenary.busted)
tests/helpers/          - Shared test utilities
tests/minimal_init.lua  - Minimal Neovim config for test runner
```
