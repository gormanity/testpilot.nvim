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

  describe("open_test", function()
    it("returns false when no file in buffer", function()
      local original_expand = vim.fn.expand
      vim.fn.expand = function()
        return ""
      end
      local msgs, restore_notify = sim.mock_notify()

      local result = testpilot.open_test()

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

      local result = testpilot.open_test()

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

      local result = testpilot.open_test()

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

      local result = testpilot.open_test({ open_method = "tabedit" })

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

      local result = testpilot.open_test()

      assert.is_false(result)
      assert.are.equal(0, #cmds)

      vim.fn.expand = original_expand
      restore_fr()
      restore_cmd()
      restore_notify()
    end)
  end)
end)
