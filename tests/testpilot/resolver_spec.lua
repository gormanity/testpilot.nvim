local go = require("testpilot.languages.go")
local python = require("testpilot.languages.python")
local typescript = require("testpilot.languages.typescript")
local rust = require("testpilot.languages.rust")
local lua_lang = require("testpilot.languages.lua")
local resolver = require("testpilot.resolver")

describe("testpilot.languages.go", function()
  describe("test_function_name", function()
    it("prepends Test to the function name", function()
      assert.are.equal("TestHandleRequest", go.test_function_name("HandleRequest"))
    end)

    it("works with single-word names", function()
      assert.are.equal("TestMain", go.test_function_name("Main"))
    end)
  end)

  describe("test_function_pattern", function()
    it("returns a pattern matching Go test function declaration", function()
      local pattern = go.test_function_pattern("HandleRequest")
      assert.are.equal("^func TestHandleRequest[(_]", pattern)
    end)
  end)

  describe("candidates", function()
    it("returns _test.go candidate for a .go file", function()
      local result = go.candidates("/project/pkg/", "handler.go")
      assert.are.same({ "/project/pkg/handler_test.go" }, result)
    end)

    it("returns empty for non-.go file", function()
      local result = go.candidates("/project/", "main.py")
      assert.are.same({}, result)
    end)

    it("handles files already named _test.go", function()
      local result = go.candidates("/project/", "handler_test.go")
      assert.are.same({ "/project/handler_test_test.go" }, result)
    end)

    it("handles path with trailing slash", function()
      local result = go.candidates("/a/b/c/", "server.go")
      assert.are.same({ "/a/b/c/server_test.go" }, result)
    end)
  end)
end)

describe("testpilot.languages.python", function()
  describe("candidates", function()
    it("returns test_ and _test candidates for a .py file", function()
      local result = python.candidates("/project/src/", "utils.py")
      assert.are.same({
        "/project/src/test_utils.py",
        "/project/src/utils_test.py",
      }, result)
    end)

    it("returns empty for non-.py file", function()
      local result = python.candidates("/project/", "main.go")
      assert.are.same({}, result)
    end)
  end)
end)

describe("testpilot.languages.typescript", function()
  describe("candidates", function()
    it("returns .test.ts and .spec.ts candidates for a .ts file", function()
      local result = typescript.candidates("/project/src/", "utils.ts")
      assert.are.same({
        "/project/src/utils.test.ts",
        "/project/src/utils.spec.ts",
      }, result)
    end)

    it("preserves .tsx extension", function()
      local result = typescript.candidates("/project/src/", "App.tsx")
      assert.are.same({
        "/project/src/App.test.tsx",
        "/project/src/App.spec.tsx",
      }, result)
    end)

    it("handles .js files", function()
      local result = typescript.candidates("/project/src/", "index.js")
      assert.are.same({
        "/project/src/index.test.js",
        "/project/src/index.spec.js",
      }, result)
    end)

    it("handles .jsx files", function()
      local result = typescript.candidates("/project/src/", "Button.jsx")
      assert.are.same({
        "/project/src/Button.test.jsx",
        "/project/src/Button.spec.jsx",
      }, result)
    end)

    it("returns empty for non-js/ts file", function()
      local result = typescript.candidates("/project/", "main.go")
      assert.are.same({}, result)
    end)
  end)
end)

describe("testpilot.languages.rust", function()
  describe("candidates", function()
    it("returns _test.rs and integration test candidates", function()
      local result = rust.candidates("/project/src/", "lib.rs")
      assert.are.same({
        "/project/src/lib_test.rs",
        "/project/tests/lib.rs",
      }, result)
    end)

    it("returns empty for non-.rs file", function()
      local result = rust.candidates("/project/", "main.go")
      assert.are.same({}, result)
    end)
  end)
end)

describe("testpilot.languages.lua", function()
  describe("candidates", function()
    it("returns _spec.lua candidate for a .lua file", function()
      local result = lua_lang.candidates("/project/lua/", "config.lua")
      assert.are.same({ "/project/lua/config_spec.lua" }, result)
    end)

    it("returns empty for non-.lua file", function()
      local result = lua_lang.candidates("/project/", "main.go")
      assert.are.same({}, result)
    end)
  end)
end)

describe("testpilot.resolver", function()
  describe("resolve", function()
    it("dispatches .go files to the Go resolver", function()
      local candidates, err = resolver.resolve("/project/pkg/handler.go")
      assert.is_nil(err)
      assert.are.same({ "/project/pkg/handler_test.go" }, candidates)
    end)

    it("dispatches .py files to the Python resolver", function()
      local candidates, err = resolver.resolve("/project/src/utils.py")
      assert.is_nil(err)
      assert.are.same({
        "/project/src/test_utils.py",
        "/project/src/utils_test.py",
      }, candidates)
    end)

    it("dispatches .ts files to the TypeScript resolver", function()
      local candidates, err = resolver.resolve("/project/src/utils.ts")
      assert.is_nil(err)
      assert.are.same({
        "/project/src/utils.test.ts",
        "/project/src/utils.spec.ts",
      }, candidates)
    end)

    it("dispatches .tsx files to the TypeScript resolver", function()
      local candidates, err = resolver.resolve("/project/src/App.tsx")
      assert.is_nil(err)
      assert.are.same({
        "/project/src/App.test.tsx",
        "/project/src/App.spec.tsx",
      }, candidates)
    end)

    it("dispatches .rs files to the Rust resolver", function()
      local candidates, err = resolver.resolve("/project/src/lib.rs")
      assert.is_nil(err)
      assert.are.same({
        "/project/src/lib_test.rs",
        "/project/tests/lib.rs",
      }, candidates)
    end)

    it("dispatches .lua files to the Lua resolver", function()
      local candidates, err = resolver.resolve("/project/lua/config.lua")
      assert.is_nil(err)
      assert.are.same({ "/project/lua/config_spec.lua" }, candidates)
    end)

    it("returns error for unsupported extension", function()
      local candidates, err = resolver.resolve("/project/main.rb")
      assert.is_nil(candidates)
      assert.is_truthy(err:find("No resolver for extension"))
    end)

    it("returns error for file with no extension", function()
      local candidates, err = resolver.resolve("/project/Makefile")
      assert.is_nil(candidates)
      assert.is_truthy(err:find("No resolver for extension"))
    end)
  end)

  describe("resolve_function", function()
    it("returns candidates, pattern, and test name for a Go file", function()
      local candidates, pattern, test_name, err = resolver.resolve_function("/project/pkg/handler.go", "HandleRequest")
      assert.is_nil(err)
      assert.are.same({ "/project/pkg/handler_test.go" }, candidates)
      assert.are.equal("^func TestHandleRequest[(_]", pattern)
      assert.are.equal("TestHandleRequest", test_name)
    end)

    it("returns error for unsupported extension", function()
      local candidates, pattern, test_name, err = resolver.resolve_function("/project/main.rb", "foo")
      assert.is_nil(candidates)
      assert.is_nil(pattern)
      assert.is_nil(test_name)
      assert.is_truthy(err:find("No resolver for extension"))
    end)

    it("returns error for language without function support", function()
      local candidates, pattern, test_name, err = resolver.resolve_function("/project/src/utils.py", "foo")
      assert.is_nil(candidates)
      assert.is_nil(pattern)
      assert.is_nil(test_name)
      assert.is_truthy(err:find("does not support function"))
    end)
  end)
end)
