local config = require("testpilot.config")
local resolver = require("testpilot.resolver")
local navigator = require("testpilot.navigator")

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

return M
