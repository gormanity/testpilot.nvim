local config = require("testpilot.config")

local M = {}

function M.open(candidates)
  local cfg = config.get()

  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then
      local escaped = vim.fn.fnameescape(path)
      vim.cmd(cfg.open_method .. " " .. escaped)
      if cfg.notify then
        vim.notify("testpilot: opened " .. path, vim.log.levels.INFO)
      end
      return true, path
    end
  end

  if cfg.notify then
    vim.notify("testpilot: no test file found", vim.log.levels.WARN)
  end
  return false, "no test file found"
end

return M
