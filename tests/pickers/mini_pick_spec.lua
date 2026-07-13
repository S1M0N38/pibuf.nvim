---@module 'luassert'

-- mini.pick adapter wiring tests. A fake `mini.pick` is injected into
-- package.loaded exposing `.start` and `.builtin.files`; both return the chosen
-- item (mini.pick is synchronous), and the preview function is driven by hand.

local adapter = require("pibuf.pickers.mini_pick")

local saved, captured

before_each(function()
  saved = package.loaded["mini.pick"]
  package.loaded["mini.pick"] = nil
  captured = {}
  package.loaded["mini.pick"] = {
    start = function(opts)
      captured.start_opts = opts
      return captured.start_return
    end,
    builtin = {
      files = function(local_opts, opts)
        captured.files_local = local_opts
        captured.files_opts = opts
        return captured.files_return
      end,
    },
  }
end)

after_each(function()
  package.loaded["mini.pick"] = saved
  package.loaded["pibuf.pickers.mini_pick"] = nil
end)

describe("mini_pick adapter", function()
  describe("files", function()
    it("calls on_select with the chosen file (relative to cwd)", function()
      captured.files_return = "lua/pibuf/init.lua"
      local got
      adapter.files("/proj", function(path)
        got = path
      end)
      assert.are.equal("lua/pibuf/init.lua", got)
    end)

    it("scopes the picker to cwd", function()
      captured.files_return = nil
      adapter.files("/proj", function() end)
      assert.are.equal("/proj", captured.files_opts.source.cwd)
    end)

    it("does not call on_select when nothing is chosen", function()
      captured.files_return = nil
      local called = false
      adapter.files("/proj", function()
        called = true
      end)
      assert.is_false(called)
    end)
  end)

  describe("items", function()
    it("calls on_select with the chosen item's value", function()
      captured.start_return = "alpha"
      local got
      adapter.items(
        { { value = "alpha", preview = "Alpha skill" }, { value = "beta", preview = "Beta skill" } },
        { title = " pibuf: /skill " },
        function(v)
          got = v
        end
      )
      assert.are.equal("alpha", got)
      assert.are.same({ "alpha", "beta" }, captured.start_opts.source.items)
      assert.are.equal(" pibuf: /skill ", captured.start_opts.source.name)
    end)

    it("forwards the preview body for the highlighted entry", function()
      captured.start_return = nil
      adapter.items({
        { value = "alpha", preview = "Alpha skill" },
        { value = "beta", preview = "Beta skill" },
      }, { title = "t" }, function() end)
      local preview = captured.start_opts.source.preview

      local buf = vim.api.nvim_create_buf(false, true)
      preview(buf, "alpha")
      assert.are.same({ "Alpha skill" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
      assert.are.equal("markdown", vim.bo[buf].filetype)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("does not call on_select when nothing is chosen", function()
      captured.start_return = nil
      local called = false
      adapter.items({ { value = "x", preview = "x" } }, { title = "t" }, function()
        called = true
      end)
      assert.is_false(called)
    end)
  end)
end)
