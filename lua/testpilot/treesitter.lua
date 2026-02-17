local M = {}

local function_node_types = {
  function_declaration = true,
  method_declaration = true,
  function_definition = true,
}

function M.get_function_name()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  local node = vim.treesitter.get_node({ pos = { row, col } })
  if not node then
    return nil
  end

  while node do
    if function_node_types[node:type()] then
      local name_node = node:field("name")[1]
      if name_node then
        return vim.treesitter.get_node_text(name_node, 0)
      end
      return nil
    end
    node = node:parent()
  end

  return nil
end

return M
