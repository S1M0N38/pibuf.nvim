---@module 'luassert'

local pibuf = require("pibuf")

describe("setup", function()
  it("sets did_setup to true", function()
    pibuf.did_setup = false
    pibuf.setup({})
    assert.is_true(pibuf.did_setup)
  end)

  it("warns but does not error on double setup", function()
    pibuf.did_setup = false
    pibuf.setup({ name = "first" })
    assert.has_no.errors(function()
      pibuf.setup({ name = "second" })
    end)
    assert.is_true(pibuf.did_setup)
  end)

  it("activate is idempotent (autocmds don't stack)", function()
    pibuf.did_setup = false
    pibuf.setup({})
    local before = #vim.api.nvim_get_autocmds({ group = "pibuf" })
    pibuf.did_setup = false
    pibuf.setup({})
    local after = #vim.api.nvim_get_autocmds({ group = "pibuf" })
    assert.are.equal(before, after)
  end)
end)

describe("refresh", function()
  it("does not error", function()
    assert.has_no.errors(function()
      pibuf.refresh()
    end)
  end)
end)

describe("filetype detection", function()
  local tmp ---@type string

  before_each(function()
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
end)
