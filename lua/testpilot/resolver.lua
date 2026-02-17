local M = {}

local extension_map = {
  go = "testpilot.languages.go",
  py = "testpilot.languages.python",
  ts = "testpilot.languages.typescript",
  tsx = "testpilot.languages.typescript",
  js = "testpilot.languages.typescript",
  jsx = "testpilot.languages.typescript",
  rs = "testpilot.languages.rust",
  lua = "testpilot.languages.lua",
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

function M.resolve_function(filepath, func_name)
  local ext = vim.fn.fnamemodify(filepath, ":e")

  local module_name = extension_map[ext]
  if not module_name then
    return nil, nil, nil, "No resolver for extension: " .. ext
  end

  local lang = require(module_name)
  if not lang.test_function_pattern then
    return nil, nil, nil, "Language does not support function-level navigation"
  end

  local path = vim.fn.fnamemodify(filepath, ":h") .. "/"
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local candidates = lang.candidates(path, filename)
  if #candidates == 0 then
    return nil, nil, nil, "No test candidates for: " .. filepath
  end

  local pattern = lang.test_function_pattern(func_name)
  local test_name = lang.test_function_name(func_name)
  return candidates, pattern, test_name, nil
end

return M
