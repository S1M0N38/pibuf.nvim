---@module 'luassert'

-- fzf-lua adapter wiring tests. A fake `fzf-lua` is injected into
-- package.loaded exposing `.files` and `.fzf_exec`; the default action and the
-- preview function are driven by hand to assert on_select and preview forwarding.

local adapter = require("pibuf.pickers.fzf-lua")

local saved, captured

before_each(function()
  saved = package.loaded["fzf-lua"]
  package.loaded["fzf-lua"] = nil
  captured = {}
end)

after_each(function()
  package.loaded["fzf-lua"] = saved
  package.loaded["pibuf.pickers.fzf-lua"] = nil
end)

describe("fzf-lua adapter", function()
  describe("files", function()
    before_each(function()
      package.loaded["fzf-lua"] = {
        files = function(opts)
          captured.files_opts = opts
          opts.actions["default"]({ "lua/pibuf/init.lua" })
        end,
      }
    end)

    it("calls on_select with the selected file (relative to cwd)", function()
      local got
      adapter.files("/proj", function(path)
        got = path
      end)
      assert.are.equal("lua/pibuf/init.lua", got)
    end)

    it("scopes files to cwd", function()
      adapter.files("/proj", function() end)
      assert.are.equal("/proj", captured.files_opts.cwd)
    end)

    it("does not call on_select when nothing is chosen", function()
      package.loaded["fzf-lua"].files = function(opts)
        opts.actions["default"](nil)
      end
      local called = false
      adapter.files("/proj", function()
        called = true
      end)
      assert.is_false(called)
    end)
  end)

  describe("items", function()
    before_each(function()
      package.loaded["fzf-lua"] = {
        fzf_exec = function(contents, opts)
          captured.contents = contents
          captured.opts = opts
        end,
      }
    end)

    it("wires on_select to the default action (value)", function()
      local items = { { value = "alpha", preview = "Alpha skill" } }
      local got
      adapter.items(items, { title = " pibuf: /skill " }, function(v)
        got = v
      end)
      assert.are.same({ "alpha" }, captured.contents)
      assert.are.equal(" pibuf: /skill ", captured.opts.prompt)
      captured.opts.actions["default"]({ "alpha" })
      assert.are.equal("alpha", got)
    end)

    it("forwards the preview body for the highlighted entry", function()
      local items = {
        { value = "alpha", preview = "Alpha skill" },
        { value = "beta", preview = "Beta skill" },
      }
      adapter.items(items, { title = "t" }, function() end)
      assert.are.equal("Alpha skill", captured.opts.preview({ "alpha" }))
      assert.are.equal("Beta skill", captured.opts.preview({ "beta" }))
    end)

    it("does not call on_select when nothing is chosen", function()
      local called = false
      adapter.items({ { value = "x", preview = "x" } }, { title = "t" }, function()
        called = true
      end)
      captured.opts.actions["default"](nil)
      assert.is_false(called)
    end)
  end)
end)
