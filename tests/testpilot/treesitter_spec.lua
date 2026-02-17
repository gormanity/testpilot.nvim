local treesitter = require("testpilot.treesitter")

describe("testpilot.treesitter", function()
  describe("get_function_name", function()
    it("returns function name from a function_declaration node", function()
      local original_get_cursor = vim.api.nvim_win_get_cursor
      vim.api.nvim_win_get_cursor = function()
        return { 5, 0 }
      end

      local name_node = {
        type = function()
          return "identifier"
        end,
      }

      local func_node = {
        type = function()
          return "function_declaration"
        end,
        field = function(_, field_name)
          if field_name == "name" then
            return { name_node }
          end
          return {}
        end,
        parent = function()
          return nil
        end,
      }

      local original_get_node = vim.treesitter.get_node
      vim.treesitter.get_node = function()
        return func_node
      end

      local original_get_text = vim.treesitter.get_node_text
      vim.treesitter.get_node_text = function()
        return "HandleRequest"
      end

      local result = treesitter.get_function_name()
      assert.are.equal("HandleRequest", result)

      vim.api.nvim_win_get_cursor = original_get_cursor
      vim.treesitter.get_node = original_get_node
      vim.treesitter.get_node_text = original_get_text
    end)

    it("walks up to parent to find function node", function()
      local original_get_cursor = vim.api.nvim_win_get_cursor
      vim.api.nvim_win_get_cursor = function()
        return { 10, 5 }
      end

      local name_node = {
        type = function()
          return "identifier"
        end,
      }

      local func_node = {
        type = function()
          return "method_declaration"
        end,
        field = function(_, field_name)
          if field_name == "name" then
            return { name_node }
          end
          return {}
        end,
        parent = function()
          return nil
        end,
      }

      local inner_node = {
        type = function()
          return "block"
        end,
        parent = function()
          return func_node
        end,
      }

      local original_get_node = vim.treesitter.get_node
      vim.treesitter.get_node = function()
        return inner_node
      end

      local original_get_text = vim.treesitter.get_node_text
      vim.treesitter.get_node_text = function()
        return "ServeHTTP"
      end

      local result = treesitter.get_function_name()
      assert.are.equal("ServeHTTP", result)

      vim.api.nvim_win_get_cursor = original_get_cursor
      vim.treesitter.get_node = original_get_node
      vim.treesitter.get_node_text = original_get_text
    end)

    it("returns nil when no treesitter node at cursor", function()
      local original_get_cursor = vim.api.nvim_win_get_cursor
      vim.api.nvim_win_get_cursor = function()
        return { 1, 0 }
      end

      local original_get_node = vim.treesitter.get_node
      vim.treesitter.get_node = function()
        return nil
      end

      local result = treesitter.get_function_name()
      assert.is_nil(result)

      vim.api.nvim_win_get_cursor = original_get_cursor
      vim.treesitter.get_node = original_get_node
    end)

    it("returns nil when cursor is not inside a function", function()
      local original_get_cursor = vim.api.nvim_win_get_cursor
      vim.api.nvim_win_get_cursor = function()
        return { 1, 0 }
      end

      local top_node = {
        type = function()
          return "source_file"
        end,
        parent = function()
          return nil
        end,
      }

      local original_get_node = vim.treesitter.get_node
      vim.treesitter.get_node = function()
        return top_node
      end

      local result = treesitter.get_function_name()
      assert.is_nil(result)

      vim.api.nvim_win_get_cursor = original_get_cursor
      vim.treesitter.get_node = original_get_node
    end)
  end)
end)
