local M = {}

function M.candidates(path, filename)
  local base = filename:match("^(.+)%.py$")
  if not base then
    return {}
  end
  return {
    path .. "test_" .. base .. ".py",
    path .. base .. "_test.py",
  }
end

return M
