local config = require("testpilot.config")
local resolver = require("testpilot.resolver")
local navigator = require("testpilot.navigator")
local treesitter = require("testpilot.treesitter")

local M = {}

function M.setup(opts)
  config.apply(opts)
end

function M.open_test(opts)
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    if config.get().notify then
      vim.notify("testpilot: no file in current buffer", vim.log.levels.WARN)
    end
    return false
  end

  local candidates, err = resolver.resolve(filepath)
  if not candidates then
    if config.get().notify then
      vim.notify("testpilot: " .. err, vim.log.levels.WARN)
    end
    return false
  end

  local ok, _ = navigator.open(candidates, opts)
  return ok
end

function M.open_test_function(opts)
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    if config.get().notify then
      vim.notify("testpilot: no file in current buffer", vim.log.levels.WARN)
    end
    return false
  end

  local func_name = treesitter.get_function_name()
  if not func_name then
    if config.get().notify then
      vim.notify("testpilot: no function at cursor", vim.log.levels.WARN)
    end
    return false
  end

  local candidates, pattern, err = resolver.resolve_function(filepath, func_name)
  if not candidates then
    if config.get().notify then
      vim.notify("testpilot: " .. err, vim.log.levels.WARN)
    end
    return false
  end

  opts = opts or {}
  opts.search_pattern = pattern
  local ok, _ = navigator.open(candidates, opts)
  return ok
end

return M
