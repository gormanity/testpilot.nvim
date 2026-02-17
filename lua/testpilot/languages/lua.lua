local M = {}

function M.candidates(path, filename)
  local base = filename:match("^(.+)%.lua$")
  if not base then
    return {}
  end
  return { path .. base .. "_spec.lua" }
end

return M
