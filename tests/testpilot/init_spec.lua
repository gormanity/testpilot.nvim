local testpilot = require("testpilot")
local config = require("testpilot.config")
local sim = require("helpers.simulation")

describe("testpilot", function()
  before_each(function()
    config.reset()
  end)

  describe("setup", function()
    it("applies configuration", function()
      testpilot.setup({ open_method = "split", notify = false })
      assert.are.equal("split", config.get().open_method)
      assert.is_false(config.get().notify)
    end)

    it("works with no arguments", function()
      testpilot.setup()
      assert.are.equal("vsplit", config.get().open_method)
    end)
  end)

  describe("open_test_file", function()
    it("returns false when no file in buffer", function()
      local original_expand = vim.fn.expand
      vim.fn.expand = function()
        return ""
      end
      local msgs, restore_notify = sim.mock_notify()

      local result = testpilot.open_test_file()

      assert.is_false(result)
      assert.are.equal(1, #msgs)
      assert.is_truthy(msgs[1].msg:find("no file"))

      vim.fn.expand = original_expand
      restore_notify()
    end)

    it("returns false for unsupported file type", function()
      local original_expand = vim.fn.expand
      vim.fn.expand = function()
        return "/project/main.rb"
      end
      local msgs, restore_notify = sim.mock_notify()

      local result = testpilot.open_test_file()

      assert.is_false(result)
      assert.are.equal(1, #msgs)
      assert.is_truthy(msgs[1].msg:find("No resolver"))

      vim.fn.expand = original_expand
      restore_notify()
    end)

    it("opens test file for a Go source file", function()
      local original_expand = vim.fn.expand
      vim.fn.expand = function()
        return "/project/handler.go"
      end
      local restore_fr = sim.mock_filereadable({ ["/project/handler_test.go"] = true })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()

      local result = testpilot.open_test_file()

      assert.is_true(result)
      assert.are.equal(1, #cmds)
      assert.is_truthy(cmds[1]:find("handler_test.go"))

      vim.fn.expand = original_expand
      restore_fr()
      restore_cmd()
      restore_notify()
    end)

    it("passes opts.open_method through to navigator", function()
      local original_expand = vim.fn.expand
      vim.fn.expand = function()
        return "/project/handler.go"
      end
      local restore_fr = sim.mock_filereadable({ ["/project/handler_test.go"] = true })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()

      local result = testpilot.open_test_file({ open_method = "tabedit" })

      assert.is_true(result)
      assert.is_truthy(cmds[1]:find("^tabedit "))

      vim.fn.expand = original_expand
      restore_fr()
      restore_cmd()
      restore_notify()
    end)

    it("returns false when test file does not exist", function()
      local original_expand = vim.fn.expand
      vim.fn.expand = function()
        return "/project/handler.go"
      end
      local restore_fr = sim.mock_filereadable({})
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()

      local result = testpilot.open_test_file()

      assert.is_false(result)
      assert.are.equal(0, #cmds)

      vim.fn.expand = original_expand
      restore_fr()
      restore_cmd()
      restore_notify()
    end)
  end)

  describe("open_test_function", function()
    it("returns false when no file in buffer", function()
      local original_expand = vim.fn.expand
      vim.fn.expand = function()
        return ""
      end
      local msgs, restore_notify = sim.mock_notify()

      local result = testpilot.open_test_function()

      assert.is_false(result)
      assert.are.equal(1, #msgs)
      assert.is_truthy(msgs[1].msg:find("no file"))

      vim.fn.expand = original_expand
      restore_notify()
    end)

    it("returns false when no function at cursor", function()
      local original_expand = vim.fn.expand
      vim.fn.expand = function()
        return "/project/handler.go"
      end

      local original_get_cursor = vim.api.nvim_win_get_cursor
      vim.api.nvim_win_get_cursor = function()
        return { 1, 0 }
      end
      local original_get_node = vim.treesitter.get_node
      vim.treesitter.get_node = function()
        return nil
      end

      local msgs, restore_notify = sim.mock_notify()

      local result = testpilot.open_test_function()

      assert.is_false(result)
      assert.are.equal(1, #msgs)
      assert.is_truthy(msgs[1].msg:find("no function"))

      vim.fn.expand = original_expand
      vim.api.nvim_win_get_cursor = original_get_cursor
      vim.treesitter.get_node = original_get_node
      restore_notify()
    end)

    it("opens test file and jumps to test function for Go", function()
      local original_expand = vim.fn.expand
      vim.fn.expand = function()
        return "/project/handler.go"
      end

      -- Mock treesitter to return a function name
      local name_node = {}
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
      local original_get_cursor = vim.api.nvim_win_get_cursor
      vim.api.nvim_win_get_cursor = function()
        return { 5, 0 }
      end
      local original_get_node = vim.treesitter.get_node
      vim.treesitter.get_node = function()
        return func_node
      end
      local original_get_text = vim.treesitter.get_node_text
      vim.treesitter.get_node_text = function()
        return "HandleRequest"
      end

      local restore_fr = sim.mock_filereadable({ ["/project/handler_test.go"] = true })
      local restore_rf = sim.mock_readfile({
        ["/project/handler_test.go"] = { "package project", "", "func TestHandleRequest(t *testing.T) {" },
      })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()
      local search_calls = {}
      local original_search = vim.fn.search
      vim.fn.search = function(pattern)
        table.insert(search_calls, pattern)
        return 3
      end

      local result = testpilot.open_test_function()

      assert.is_true(result)
      assert.are.equal(1, #cmds)
      assert.is_truthy(cmds[1]:find("handler_test.go"))
      assert.are.equal(1, #search_calls)
      assert.are.equal("^func TestHandleRequest[(_]", search_calls[1])

      vim.fn.expand = original_expand
      vim.api.nvim_win_get_cursor = original_get_cursor
      vim.treesitter.get_node = original_get_node
      vim.treesitter.get_node_text = original_get_text
      vim.fn.search = original_search
      restore_fr()
      restore_rf()
      restore_cmd()
      restore_notify()
    end)

    it("returns false for unsupported file type", function()
      local original_expand = vim.fn.expand
      vim.fn.expand = function()
        return "/project/main.rb"
      end

      local name_node = {}
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
      local original_get_cursor = vim.api.nvim_win_get_cursor
      vim.api.nvim_win_get_cursor = function()
        return { 5, 0 }
      end
      local original_get_node = vim.treesitter.get_node
      vim.treesitter.get_node = function()
        return func_node
      end
      local original_get_text = vim.treesitter.get_node_text
      vim.treesitter.get_node_text = function()
        return "foo"
      end

      local msgs, restore_notify = sim.mock_notify()

      local result = testpilot.open_test_function()

      assert.is_false(result)
      assert.are.equal(1, #msgs)

      vim.fn.expand = original_expand
      vim.api.nvim_win_get_cursor = original_get_cursor
      vim.treesitter.get_node = original_get_node
      vim.treesitter.get_node_text = original_get_text
      restore_notify()
    end)
  end)
end)
