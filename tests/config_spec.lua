---@module 'luassert'

local config = require("pibuf.config")

describe("config", function()
  local saved

  before_each(function()
    saved = config.picker
  end)

  after_each(function()
    config.picker = saved
  end)

  describe("default", function()
    it("defaults picker to 'snacks' on a fresh load", function()
      -- module default is snacks; setup() with no arg must not clobber it
      config.picker = "snacks"
      config.setup()
      assert.are.equal("snacks", config.picker)
    end)
  end)

  describe("enum validation", function()
    for _, name in ipairs({ "snacks", "telescope", "fzf-lua", "mini.pick" }) do
      it(("accepts %q"):format(name), function()
        config.setup({ picker = name })
        assert.are.equal(name, config.picker)
      end)
    end

    it("errors on an unknown picker", function()
      assert.has_error(function()
        config.setup({ picker = "fzf" })
      end, 'pibuf: unknown picker "fzf" (want one of snacks, telescope, fzf-lua, mini.pick)')
    end)

    it("errors on a typo", function()
      assert.has_error(function()
        config.setup({ picker = "snakcs" })
      end)
    end)
  end)
end)
