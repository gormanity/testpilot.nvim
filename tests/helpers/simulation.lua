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
