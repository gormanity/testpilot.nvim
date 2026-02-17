local config = require("testpilot.config")

local M = {}

function M.open(candidates, opts)
  local cfg = config.get()
  local open_method = (opts and opts.open_method) or cfg.open_method

  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then
      local bufnr = vim.fn.bufnr(path)
      if bufnr ~= -1 then
        local wins = vim.fn.win_findbuf(bufnr)
        if #wins > 0 then
          vim.api.nvim_set_current_win(wins[1])
          if cfg.notify then
            vim.notify("testpilot: focused " .. path, vim.log.levels.INFO)
          end
          return true, path
        end
      end
      local escaped = vim.fn.fnameescape(path)
      vim.cmd(open_method .. " " .. escaped)
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
