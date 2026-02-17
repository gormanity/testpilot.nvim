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

    it("uses opts.open_method override over config", function()
      config.apply({ open_method = "vsplit" })
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()

      navigator.open({ "/pkg/handler_test.go" }, { open_method = "tabedit" })

      assert.is_truthy(cmds[1]:find("^tabedit "))

      restore_fr()
      restore_cmd()
      restore_notify()
    end)

    it("focuses existing window instead of opening a duplicate", function()
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local restore_bufnr = sim.mock_bufnr({ ["/pkg/handler_test.go"] = 42 })
      local restore_wfb = sim.mock_win_findbuf({ [42] = { 1001 } })
      local win_calls, restore_scw = sim.mock_set_current_win()
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local msgs, restore_notify = sim.mock_notify()

      local ok, path = navigator.open({ "/pkg/handler_test.go" })

      assert.is_true(ok)
      assert.are.equal("/pkg/handler_test.go", path)
      assert.are.equal(1, #win_calls)
      assert.are.equal(1001, win_calls[1])
      assert.are.equal(0, #cmds)
      assert.are.equal(1, #msgs)
      assert.is_truthy(msgs[1].msg:find("focused"))

      restore_fr()
      restore_bufnr()
      restore_wfb()
      restore_scw()
      restore_cmd()
      restore_notify()
    end)

    it("opens normally when buffer is loaded but not in any window", function()
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local restore_bufnr = sim.mock_bufnr({ ["/pkg/handler_test.go"] = 42 })
      local restore_wfb = sim.mock_win_findbuf({})
      local win_calls, restore_scw = sim.mock_set_current_win()
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()

      local ok, path = navigator.open({ "/pkg/handler_test.go" })

      assert.is_true(ok)
      assert.are.equal("/pkg/handler_test.go", path)
      assert.are.equal(0, #win_calls)
      assert.are.equal(1, #cmds)
      assert.is_truthy(cmds[1]:find("vsplit"))

      restore_fr()
      restore_bufnr()
      restore_wfb()
      restore_scw()
      restore_cmd()
      restore_notify()
    end)

    it("opens normally when buffer is not loaded at all", function()
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local restore_bufnr = sim.mock_bufnr({})
      local restore_wfb = sim.mock_win_findbuf({})
      local win_calls, restore_scw = sim.mock_set_current_win()
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()

      local ok, path = navigator.open({ "/pkg/handler_test.go" })

      assert.is_true(ok)
      assert.are.equal("/pkg/handler_test.go", path)
      assert.are.equal(0, #win_calls)
      assert.are.equal(1, #cmds)

      restore_fr()
      restore_bufnr()
      restore_wfb()
      restore_scw()
      restore_cmd()
      restore_notify()
    end)

    it("opens file and jumps when search_pattern matches", function()
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local restore_rf = sim.mock_readfile({
        ["/pkg/handler_test.go"] = { "package pkg", "", "func TestHandleRequest_OK(t *testing.T) {" },
      })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()
      local search_calls = {}
      local original_search = vim.fn.search
      vim.fn.search = function(pattern)
        table.insert(search_calls, pattern)
        return 3
      end

      local ok, path = navigator.open(
        { "/pkg/handler_test.go" },
        { search_pattern = "^func TestHandleRequest[(_]" }
      )

      assert.is_true(ok)
      assert.are.equal("/pkg/handler_test.go", path)
      assert.are.equal(1, #cmds)
      assert.are.equal(1, #search_calls)
      assert.are.equal("^func TestHandleRequest[(_]", search_calls[1])

      vim.fn.search = original_search
      restore_fr()
      restore_rf()
      restore_cmd()
      restore_notify()
    end)

    it("does not call search when no search_pattern provided", function()
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()
      local search_calls = {}
      local original_search = vim.fn.search
      vim.fn.search = function(pattern)
        table.insert(search_calls, pattern)
        return 1
      end

      navigator.open({ "/pkg/handler_test.go" })

      assert.are.equal(0, #search_calls)

      vim.fn.search = original_search
      restore_fr()
      restore_cmd()
      restore_notify()
    end)

    it("jumps when focusing existing window with search_pattern", function()
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local restore_rf = sim.mock_readfile({
        ["/pkg/handler_test.go"] = { "package pkg", "", "func TestFoo(t *testing.T) {" },
      })
      local restore_bufnr = sim.mock_bufnr({ ["/pkg/handler_test.go"] = 42 })
      local restore_wfb = sim.mock_win_findbuf({ [42] = { 1001 } })
      local win_calls, restore_scw = sim.mock_set_current_win()
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local _, restore_notify = sim.mock_notify()
      local search_calls = {}
      local original_search = vim.fn.search
      vim.fn.search = function(pattern)
        table.insert(search_calls, pattern)
        return 3
      end

      local ok, path = navigator.open(
        { "/pkg/handler_test.go" },
        { search_pattern = "^func TestFoo[(_]" }
      )

      assert.is_true(ok)
      assert.are.equal(1, #win_calls)
      assert.are.equal(1, #search_calls)
      assert.are.equal("^func TestFoo[(_]", search_calls[1])

      vim.fn.search = original_search
      restore_fr()
      restore_rf()
      restore_bufnr()
      restore_wfb()
      restore_scw()
      restore_cmd()
      restore_notify()
    end)

    it("does not open file when search_pattern does not match", function()
      local restore_fr = sim.mock_filereadable({ ["/pkg/handler_test.go"] = true })
      local restore_rf = sim.mock_readfile({
        ["/pkg/handler_test.go"] = { "package pkg", "", "func TestOtherThing(t *testing.T) {" },
      })
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local msgs, restore_notify = sim.mock_notify()

      local ok, _ = navigator.open(
        { "/pkg/handler_test.go" },
        { search_pattern = "^func TestNonexistent[(_]", search_name = "TestNonexistent" }
      )

      assert.is_false(ok)
      assert.are.equal(0, #cmds)
      assert.are.equal(1, #msgs)
      assert.is_truthy(msgs[1].msg:find("TestNonexistent"))
      assert.is_truthy(msgs[1].msg:find("not found in test file"))
      assert.are.equal(vim.log.levels.WARN, msgs[1].level)

      restore_fr()
      restore_rf()
      restore_cmd()
      restore_notify()
    end)

    it("reports no test file when file is not readable and search_pattern given", function()
      local restore_fr = sim.mock_filereadable({})
      local restore_rf = sim.mock_readfile({})
      local cmds, restore_cmd = sim.mock_vim_cmd()
      local msgs, restore_notify = sim.mock_notify()

      local ok, _ = navigator.open(
        { "/pkg/handler_test.go" },
        { search_pattern = "^func TestFoo[(_]", search_name = "TestFoo" }
      )

      assert.is_false(ok)
      assert.are.equal(0, #cmds)
      assert.are.equal(1, #msgs)
      assert.is_truthy(msgs[1].msg:find("TestFoo"))
      assert.is_truthy(msgs[1].msg:find("no test file found"))
      assert.are.equal(vim.log.levels.WARN, msgs[1].level)

      restore_fr()
      restore_rf()
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
