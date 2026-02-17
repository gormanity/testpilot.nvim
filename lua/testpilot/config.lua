local M = {}

local defaults = {
  open_method = "vsplit",
  notify = "failures",
}

M._config = vim.deepcopy(defaults)

function M.apply(opts)
  M._config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  return M._config
end

function M.get()
  return M._config
end

function M.reset()
  M._config = vim.deepcopy(defaults)
  return M._config
end

return M
