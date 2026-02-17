local M = {}

function M.mock_vim_cmd()
  local calls = {}
  local original = vim.cmd
  vim.cmd = function(cmd)
    table.insert(calls, cmd)
  end
  return calls, function()
    vim.cmd = original
  end
end

function M.mock_filereadable(readable_files)
  local original = vim.fn.filereadable
  vim.fn.filereadable = function(path)
    if readable_files[path] then
      return 1
    end
    return 0
  end
  return function()
    vim.fn.filereadable = original
  end
end

function M.mock_bufnr(buf_map)
  local original = vim.fn.bufnr
  vim.fn.bufnr = function(path)
    if buf_map[path] then
      return buf_map[path]
    end
    return -1
  end
  return function()
    vim.fn.bufnr = original
  end
end

function M.mock_win_findbuf(win_map)
  local original = vim.fn.win_findbuf
  vim.fn.win_findbuf = function(bufnr)
    if win_map[bufnr] then
      return win_map[bufnr]
    end
    return {}
  end
  return function()
    vim.fn.win_findbuf = original
  end
end

function M.mock_set_current_win()
  local calls = {}
  local original = vim.api.nvim_set_current_win
  vim.api.nvim_set_current_win = function(winid)
    table.insert(calls, winid)
  end
  return calls, function()
    vim.api.nvim_set_current_win = original
  end
end

function M.mock_readfile(file_lines)
  local original = vim.fn.readfile
  vim.fn.readfile = function(path)
    return file_lines[path] or {}
  end
  return function()
    vim.fn.readfile = original
  end
end

function M.mock_match(results)
  local original = vim.fn.match
  vim.fn.match = function(str, pattern)
    if results then
      return results(str, pattern)
    end
    return original(str, pattern)
  end
  return function()
    vim.fn.match = original
  end
end

function M.mock_notify()
  local messages = {}
  local original = vim.notify
  vim.notify = function(msg, level)
    table.insert(messages, { msg = msg, level = level })
  end
  return messages, function()
    vim.notify = original
  end
end

return M
