local navigator = require("testpilot.navigator")
local config = require("testpilot.config")
local sim = require("helpers.simulation")

describe("testpilot.navigator", function()
  before_each(function()
    config.reset()
  end)

  describe("open", function()
    it("opens first readable candidate with configured method", function()
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local msgs, restore_notify = sim.mock_notify()

      local ok, path = navigator.open({ "/pkg/handler_test.go" })

      assert.is_true(ok)
      assert.are.equal("/pkg/handler_test.go", path)
      assert.are.equal(1, #cmds)
      assert.is_truthy(cmds[1]:find("vsplit"))
      assert.are.equal(1, #msgs)
      assert.are.equal(vim.log.levels.INFO, msgs[1].level)

      restore_fr()
      restore_cmd()
      restore_notify()
    end)

    it("skips non-readable candidates", function()
      local restore_fr = sim.mock_filereadable({ ["/pkg/b_test.go"] = true })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()

      local ok, path = navigator.open({ "/pkg/a_test.go", "/pkg/b_test.go" })

      assert.is_true(ok)
      assert.are.equal("/pkg/b_test.go", path)
      assert.are.equal(1, #cmds)

      restore_fr()
      restore_cmd()
      restore_notify()
    end)

    it("returns false when no candidates are readable", function()
      local restore_fr = sim.mock_filereadable({})
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local msgs, restore_notify = sim.mock_notify()

      local ok, msg = navigator.open({ "/pkg/handler_test.go" })

      assert.is_false(ok)
      assert.is_truthy(msg:find("no test file"))
      assert.are.equal(0, #cmds)
      assert.are.equal(1, #msgs)
      assert.are.equal(vim.log.levels.WARN, msgs[1].level)

      restore_fr()
      restore_cmd()
      restore_notify()
    end)

    it("uses configured open_method", function()
      config.apply({ open_method = "split" })
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()

      navigator.open({ "/pkg/handler_test.go" })

      assert.is_truthy(cmds[1]:find("^split "))

      restore_fr()
      restore_cmd()
      restore_notify()
    end)

    it("suppresses notifications when notify is false", function()
      config.apply({ notify = false })
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local msgs, restore_notify = sim.mock_notify()

      navigator.open({ "/pkg/handler_test.go" })

      assert.are.equal(0, #msgs)

      restore_fr()
      restore_cmd()
      restore_notify()
    end)
  end)
end)
