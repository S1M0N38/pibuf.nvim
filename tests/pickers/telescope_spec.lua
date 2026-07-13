---@module 'luassert'

-- Telescope adapter wiring tests. A fake `telescope.*` is injected into
-- package.loaded; `select_default:replace` captures the confirm action, which
-- the test drives by hand to assert on_select receives the right value and
-- that the preview text is forwarded to the buffer previewer.

local telescope_modules = {
  "telescope",
  "telescope.builtin",
  "telescope.actions",
  "telescope.actions.state",
  "telescope.pickers",
  "telescope.finders",
  "telescope.previewers",
  "telescope.config",
}

local adapter = require("pibuf.pickers.telescope")

local saved, captured, replaced

before_each(function()
  saved = {}
  for _, m in ipairs(telescope_modules) do
    saved[m] = package.loaded[m]
    package.loaded[m] = nil
  end
  captured = {}
  replaced = {}

  package.loaded["telescope.actions"] = {
    select_default = {
      replace = function(_, fn)
        replaced.select_default = fn
      end,
    },
    close = function() end,
  }
  package.loaded["telescope.actions.state"] = {
    get_selected_entry = function()
      return captured.selected
    end,
  }
end)

after_each(function()
  for m, v in pairs(saved) do
    package.loaded[m] = v
  end
  package.loaded["pibuf.pickers.telescope"] = nil
end)

describe("telescope adapter", function()
  describe("files", function()
    before_each(function()
      package.loaded["telescope.builtin"] = {
        find_files = function(opts)
          captured.files_opts = opts
          opts.attach_mappings(0, function() end)
          captured.selected = { value = "lua/pibuf/init.lua" }
          replaced.select_default()
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

    it("scopes find_files to cwd", function()
      adapter.files("/proj", function() end)
      assert.are.equal("/proj", captured.files_opts.cwd)
    end)

    it("does not call on_select when nothing is selected", function()
      package.loaded["telescope.builtin"].find_files = function(opts)
        opts.attach_mappings(0, function() end)
        captured.selected = nil
        replaced.select_default()
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
      package.loaded["telescope.pickers"] = {
        new = function(_, opts)
          captured.picker_opts = opts
          return setmetatable({}, {
            __index = {
              find = function()
                opts.attach_mappings(0, function() end)
                local em = captured.finder.entry_maker
                captured.selected = em(captured.finder.results[1])
                replaced.select_default()
              end,
            },
          })
        end,
      }
      package.loaded["telescope.finders"] = {
        new_table = function(t)
          captured.finder = t
          return {}
        end,
      }
      package.loaded["telescope.previewers"] = {
        new_buffer_previewer = function(o)
          captured.previewer_opts = o
          return {}
        end,
      }
      package.loaded["telescope.config"] = {
        values = {
          generic_sorter = function()
            return {}
          end,
        },
      }
    end)

    it("calls on_select with the selected item's value", function()
      local got
      adapter.items({ { value = "alpha", preview = "Alpha skill" } }, { title = " pibuf: /skill " }, function(v)
        got = v
      end)
      assert.are.equal("alpha", got)
    end)

    it("passes the preview text through to the buffer previewer", function()
      adapter.items({ { value = "alpha", preview = "Alpha skill" } }, { title = "t" }, function() end)
      local entry_maker = captured.finder.entry_maker
      local entry = entry_maker({ value = "alpha", preview = "Alpha skill" })
      assert.are.equal("alpha", entry.value)

      local buf = vim.api.nvim_create_buf(false, true)
      captured.previewer_opts.define_preview({ state = { bufnr = buf } }, entry, {})
      assert.are.same({ "Alpha skill" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
      assert.are.equal("markdown", vim.bo[buf].filetype)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("does not call on_select when nothing is selected", function()
      package.loaded["telescope.pickers"].new = function(_, opts)
        return setmetatable({}, {
          __index = {
            find = function()
              opts.attach_mappings(0, function() end)
              captured.selected = nil
              replaced.select_default()
            end,
          },
        })
      end
      local called = false
      adapter.items({ { value = "x", preview = "x" } }, { title = "t" }, function()
        called = true
      end)
      assert.is_false(called)
    end)
  end)
end)
