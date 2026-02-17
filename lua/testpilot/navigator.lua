local config = require("testpilot.config")

local M = {}

local function should_notify(level)
  local notify = config.get().notify
  if notify == "all" then
    return true
  elseif notify == "failures" then
    return level == vim.log.levels.WARN
  else
    return false
  end
end

local function file_contains_pattern(path, pattern)
  local lines = vim.fn.readfile(path)
  for _, line in ipairs(lines) do
    if vim.fn.match(line, pattern) ~= -1 then
      return true
    end
  end
  return false
end

function M.open(candidates, opts)
  local cfg = config.get()
  local open_method = (opts and opts.open_method) or cfg.open_method
  local search_pattern = opts and opts.search_pattern
  local search_name = opts and opts.search_name
  local found_test_file = false

  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then
      found_test_file = true
      if search_pattern and not file_contains_pattern(path, search_pattern) then
        -- File exists but doesn't contain the test function; skip it
      else
        local bufnr = vim.fn.bufnr(path)
        if bufnr ~= -1 then
          local wins = vim.fn.win_findbuf(bufnr)
          if #wins > 0 then
            vim.api.nvim_set_current_win(wins[1])
            if search_pattern then
              vim.fn.search(search_pattern)
            end
            if should_notify(vim.log.levels.INFO) then
              vim.notify("testpilot: focused " .. path, vim.log.levels.INFO)
            end
            return true, path
          end
        end
        local escaped = vim.fn.fnameescape(path)
        vim.cmd(open_method .. " " .. escaped)
        if search_pattern then
          vim.fn.search(search_pattern)
        end
        if should_notify(vim.log.levels.INFO) then
          vim.notify("testpilot: opened " .. path, vim.log.levels.INFO)
        end
        return true, path
      end
    end
  end

  if should_notify(vim.log.levels.WARN) then
    if search_pattern then
      local name = search_name or "test function"
      if found_test_file then
        vim.notify("testpilot: " .. name .. " not found in test file", vim.log.levels.WARN)
      else
        vim.notify("testpilot: no test file found for " .. name, vim.log.levels.WARN)
      end
    else
      vim.notify("testpilot: no test file found", vim.log.levels.WARN)
    end
  end
  return false, "no test file found"
end

return M
