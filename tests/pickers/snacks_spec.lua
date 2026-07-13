---@module 'luassert'

-- Adapter tests pin the *wiring* (upstream entry point → on_select) without
-- any real picker UI: a fake `snacks.picker` is injected into package.loaded,
-- its confirm/action callback is driven by hand, and we assert the adapter
-- invoked on_select with the right path/value and forwarded the preview.

local adapter = require("pibuf.pickers.snacks")

describe("snacks adapter", function()
  local saved_picker, fake

  before_each(function()
    saved_picker = package.loaded["snacks.picker"]
    fake = {}
    local picker_obj = { close = function() end }
    package.loaded["snacks.picker"] = setmetatable({
      files = function(opts)
        fake.files_opts = opts
        opts.confirm(picker_obj, { file = "lua/pibuf/init.lua", cwd = opts.cwd })
      end,
    }, {
      __call = function(_, config)
        fake.items_config = config
      end,
    })
  end)

  after_each(function()
    package.loaded["snacks.picker"] = saved_picker
  end)

  describe("files", function()
    it("calls on_select with the chosen file", function()
      local got
      adapter.files("/proj", function(path)
        got = path
      end)
      assert.are.equal("lua/pibuf/init.lua", got)
    end)

    it("scopes the picker to cwd", function()
      adapter.files("/proj", function() end)
      assert.are.equal("/proj", fake.files_opts.cwd)
    end)

    it("does not call on_select when nothing is chosen", function()
      package.loaded["snacks.picker"].files = function(opts)
        opts.confirm({ close = function() end }, nil)
      end
      local called = false
      adapter.files("/proj", function()
        called = true
      end)
      assert.is_false(called)
    end)
  end)

  describe("items", function()
    it("maps PickItems to snacks entries (with preview) and calls on_select with value", function()
      local got
      local items = {
        { value = "alpha", preview = "Alpha skill" },
        { value = "beta", preview = "Beta skill" },
      }
      adapter.items(items, { title = " pibuf: /skill " }, function(v)
        got = v
      end)

      assert.are.same({
        { text = "alpha", name = "alpha", preview = { text = "Alpha skill", ft = "markdown" } },
        { text = "beta", name = "beta", preview = { text = "Beta skill", ft = "markdown" } },
      }, fake.items_config.items)
      assert.are.equal(" pibuf: /skill ", fake.items_config.title)

      -- simulate the user confirming the first entry
      fake.items_config.confirm({ close = function() end }, fake.items_config.items[1])
      assert.are.equal("alpha", got)
    end)

    it("does not call on_select when nothing is chosen", function()
      local called = false
      adapter.items({ { value = "x", preview = "x" } }, { title = "t" }, function()
        called = true
      end)
      fake.items_config.confirm({ close = function() end }, nil)
      assert.is_false(called)
    end)
  end)
end)
