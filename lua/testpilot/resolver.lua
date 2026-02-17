local M = {}

local extension_map = {
  go = "testpilot.languages.go",
}

function M.resolve(filepath)
  local path = vim.fn.fnamemodify(filepath, ":h") .. "/"
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local ext = vim.fn.fnamemodify(filepath, ":e")

  local module_name = extension_map[ext]
  if not module_name then
    return nil, "No resolver for extension: " .. ext
  end

  local lang = require(module_name)
  local candidates = lang.candidates(path, filename)
  if #candidates == 0 then
    return nil, "No test candidates for: " .. filepath
  end

  return candidates, nil
end

return M
