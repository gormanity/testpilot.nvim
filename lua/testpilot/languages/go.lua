local M = {}

function M.candidates(path, filename)
  local base = filename:match("^(.+)%.go$")
  if not base then
    return {}
  end
  return { path .. base .. "_test.go" }
end

return M
