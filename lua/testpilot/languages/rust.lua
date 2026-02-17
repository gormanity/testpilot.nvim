local M = {}

function M.candidates(path, filename)
  local base = filename:match("^(.+)%.rs$")
  if not base then
    return {}
  end
  local parent = path:match("^(.+/)[^/]+/$")
  local result = { path .. base .. "_test.rs" }
  if parent then
    table.insert(result, parent .. "tests/" .. base .. ".rs")
  end
  return result
end

return M
