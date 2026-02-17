local M = {}

function M.candidates(path, filename)
  local base, ext = filename:match("^(.+)(%.[jt]sx?)$")
  if not base then
    return {}
  end
  return {
    path .. base .. ".test" .. ext,
    path .. base .. ".spec" .. ext,
  }
end

return M
