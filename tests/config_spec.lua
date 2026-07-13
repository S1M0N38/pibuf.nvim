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

    describe("invalid picker", function()
      local saved_notify, notify_calls

      before_each(function()
        saved_notify = vim.notify
        notify_calls = {}
        vim.notify = function(msg, level, opts)
          notify_calls[#notify_calls + 1] = { msg = msg, level = level, opts = opts }
        end
      end)

      after_each(function()
        vim.notify = saved_notify
      end)

      it("notifies ERROR and keeps the previous picker (unknown name)", function()
        config.picker = "snacks"
        config.setup({ picker = "fzf" })
        vim.wait(1000, function()
          return #notify_calls >= 1
        end)
        assert.are.equal(1, #notify_calls)
        assert.are.equal(vim.log.levels.ERROR, notify_calls[1].level)
        assert.matches('unknown picker "fzf"', notify_calls[1].msg)
        assert.matches("keeping", notify_calls[1].msg)
        assert.are.equal("snacks", config.picker)
      end)

      it("notifies ERROR and keeps the previous picker (typo)", function()
        config.picker = "telescope"
        config.setup({ picker = "snakcs" })
        vim.wait(1000, function()
          return #notify_calls >= 1
        end)
        assert.are.equal(1, #notify_calls)
        assert.are.equal(vim.log.levels.ERROR, notify_calls[1].level)
        assert.are.equal("telescope", config.picker)
      end)
    end)
  end)
end)
