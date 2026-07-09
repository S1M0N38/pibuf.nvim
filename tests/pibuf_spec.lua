---@module 'luassert'

local pibuf = require("pibuf")

describe("setup", function()
  it("is idempotent (autocmds don't stack)", function()
    pibuf.setup()
    local before = #vim.api.nvim_get_autocmds({ group = "pibuf" })
    pibuf.setup()
    local after = #vim.api.nvim_get_autocmds({ group = "pibuf" })
    assert.are.equal(before, after)
  end)
end)

describe("filetype detection", function()
  local tmp ---@type string

  before_each(function()
    pibuf.setup()
    tmp = vim.fs.joinpath(vim.uv.os_tmpdir(), "pi-editor-test-" .. tostring(vim.uv.hrtime()) .. ".pi.md")
    vim.fn.writefile({ "edit me" }, tmp)
  end)

  after_each(function()
    pcall(vim.cmd, "bdelete! " .. vim.fn.fnameescape(tmp))
    vim.fn.delete(tmp)
  end)

  it("sets filetype=pi on a pi-editor temp file", function()
    vim.cmd.edit(vim.fn.fnameescape(tmp))
    assert.are.equal("pi", vim.bo.filetype)
  end)

  it("does not set filetype=pi on an unrelated file", function()
    local other = vim.fs.joinpath(vim.uv.os_tmpdir(), "pibuf-other-" .. tostring(vim.uv.hrtime()) .. ".md")
    vim.fn.writefile({ "not pi" }, other)
    vim.cmd.edit(vim.fn.fnameescape(other))
    assert.are_not.equal("pi", vim.bo.filetype)
    pcall(vim.cmd, "bdelete! " .. vim.fn.fnameescape(other))
    vim.fn.delete(other)
  end)

  it("sets the <C-f>/<C-s> picker keymaps on a pi buffer", function()
    vim.cmd.edit(vim.fn.fnameescape(tmp))
    local function has_desc(mode, fragment)
      for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
        if m.desc and m.desc:find(fragment, 1, true) then
          return true
        end
      end
      return false
    end
    assert.is_true(has_desc("i", "@file"))
    assert.is_true(has_desc("i", "/skill"))
  end)
end)
