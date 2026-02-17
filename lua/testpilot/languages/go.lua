local M = {}

function M.candidates(path, filename)
  local base = filename:match("^(.+)%.go$")
  if not base then
    return {}
  end
  return { path .. base .. "_test.go" }
end

function M.test_function_name(func_name)
  return "Test" .. func_name
end

function M.test_function_pattern(func_name)
  return "^func " .. M.test_function_name(func_name) .. "[(_]"
end

return M
