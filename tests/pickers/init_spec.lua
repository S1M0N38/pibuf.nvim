---@module 'luassert'

local config = require("pibuf.config")
local pickers = require("pibuf.pickers")
local Skills = require("pibuf.skills")

describe("pickers dispatcher", function()
  describe("MODULES map", function()
    it("keys match config.PICKERS keys (drift guard)", function()
      local module_keys = {}
      for k in pairs(pickers.MODULES) do
        module_keys[#module_keys + 1] = k
      end
      table.sort(module_keys)
      local config_keys = {}
      for k in pairs(config.PICKERS) do
        config_keys[#config_keys + 1] = k
      end
      table.sort(config_keys)
      assert.are.same(config_keys, module_keys)
    end)

    it("maps 'mini.pick' to the underscored file", function()
      assert.are.equal("pibuf.pickers.mini_pick", pickers.MODULES["mini.pick"])
    end)
  end)

  -- A fake adapter stands in for a real backend: the dispatcher talks to it
  -- only through the files/items contract, so these tests pin the wiring
  -- (cursor capture, '@' formatting, relpath) without any picker UI.
  local function with_fake_adapter(name, adapter)
    package.loaded["pibuf.pickers." .. name] = adapter
    package.loaded[config.PICKERS[name]] = package.loaded[config.PICKERS[name]] or {}
  end

  local buf, saved_picker, saved_cwd

  before_each(function()
    saved_picker = config.picker
    saved_cwd = vim.fn.getcwd()
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
  end)

  after_each(function()
    config.picker = saved_picker
    for _, name in ipairs({ "snacks", "telescope", "fzf-lua" }) do
      package.loaded["pibuf.pickers." .. name] = nil
    end
    package.loaded["pibuf.pickers.mini_pick"] = nil
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.cmd("cd " .. vim.fn.fnameescape(saved_cwd))
  end)

  describe("files", function()
    local cwd, file_rel, file_abs

    before_each(function()
      file_rel = "sub/file.txt"
      cwd = vim.fn.resolve(vim.fs.joinpath(vim.uv.os_tmpdir(), "pibuf-files-" .. tostring(vim.uv.hrtime())))
      file_abs = cwd .. "/" .. file_rel
      vim.fn.mkdir(vim.fs.dirname(file_abs), "p")
      vim.fn.writefile({ "x" }, file_abs)
      vim.cmd("cd " .. vim.fn.fnameescape(cwd))
    end)

    after_each(function()
      vim.fn.delete(cwd, "rf")
    end)

    it("inserts '@<relpath> ' at the captured cursor on confirm (absolute path)", function()
      config.picker = "snacks"
      local captured = {}
      with_fake_adapter("snacks", {
        files = function(adapter_cwd, on_select)
          captured.cwd = adapter_cwd
          captured.on_select = on_select
        end,
        items = function() end,
      })

      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })
      vim.api.nvim_win_set_cursor(0, { 1, 5 }) -- right after "hello"

      pickers.files(buf)
      assert.are.equal(cwd, captured.cwd)
      captured.on_select(file_abs)

      vim.wait(1000, function()
        return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find("@", 1, true) ~= nil
      end)
      assert.are.equal("hello@" .. file_rel .. "  world", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
    end)

    it("inserts '@<relpath> ' when the adapter already passes a relative path", function()
      config.picker = "snacks"
      local captured = {}
      with_fake_adapter("snacks", {
        files = function(adapter_cwd, on_select)
          captured.on_select = on_select
        end,
        items = function() end,
      })

      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })
      vim.api.nvim_win_set_cursor(0, { 1, 5 })

      pickers.files(buf)
      captured.on_select(file_rel)

      vim.wait(1000, function()
        return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find("@", 1, true) ~= nil
      end)
      assert.are.equal("hello@" .. file_rel .. "  world", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
    end)
  end)

  describe("skills", function()
    local saved_discover

    before_each(function()
      saved_discover = Skills.discover
    end)

    after_each(function()
      Skills.discover = saved_discover
    end)

    it("inserts '/skill:<value> ' at the cursor and maps skills to {value, preview}", function()
      config.picker = "snacks"
      Skills.discover = function(_cwd)
        return {
          { name = "alpha", description = "Alpha skill" },
          { name = "beta", description = "Beta skill" },
        }
      end
      local captured = {}
      with_fake_adapter("snacks", {
        files = function() end,
        items = function(items, opts, on_select)
          captured.items = items
          captured.opts = opts
          captured.on_select = on_select
        end,
      })

      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "prompt text" })
      vim.api.nvim_win_set_cursor(0, { 1, 6 }) -- inside "prompt"

      pickers.skills(buf)

      assert.are.same({
        { value = "alpha", preview = "Alpha skill" },
        { value = "beta", preview = "Beta skill" },
      }, captured.items)
      assert.are.equal(" pibuf: /skill ", captured.opts.title)

      captured.on_select("alpha")
      vim.wait(1000, function()
        return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find("/skill:", 1, true) ~= nil
      end)
      assert.are.equal("prompt/skill:alpha  text", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
    end)
  end)

  describe("missing upstream", function()
    local saved_upstream, saved_notify, notify_calls

    before_each(function()
      saved_upstream = config.PICKERS["snacks"]
      saved_notify = vim.notify
      notify_calls = {}
      vim.notify = function(msg, level, opts)
        notify_calls[#notify_calls + 1] = { msg = msg, level = level, opts = opts }
      end
    end)

    after_each(function()
      config.PICKERS["snacks"] = saved_upstream
      vim.notify = saved_notify
    end)

    it("files notifies with ERROR and bails without inserting", function()
      config.picker = "snacks"
      -- point the enum at a module that will never resolve, simulating a
      -- missing upstream without depending on the host machine's plugins
      config.PICKERS["snacks"] = "pibuf.__definitely_not_installed"
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "unchanged" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      pickers.files(buf)

      vim.wait(1000, function()
        return #notify_calls >= 1
      end)
      assert.are.equal(1, #notify_calls)
      assert.are.equal(vim.log.levels.ERROR, notify_calls[1].level)
      assert.are.equal("unchanged", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
    end)
  end)
end)
