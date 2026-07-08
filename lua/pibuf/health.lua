---@class pibuf.Health
local M = {}

---Health check called by `:checkhealth pibuf`.
function M.check()
  vim.health.start("pibuf.nvim")

  if require("pibuf").did_setup then
    vim.health.ok("setup() was called")
  else
    vim.health.error("setup() was not called. Call require('pibuf').setup({}) in your config.")
  end

  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim >= 0.12")
  else
    vim.health.error("Neovim >= 0.12 is required")
  end

  if vim.fn.executable("fd") == 1 then
    vim.health.ok("`fd` found — `@file` completion uses the fast backend")
  else
    vim.health.warn("`fd` not found — falling back to vim.fs (slower). Install fd for best performance.")
  end

  if pcall(require, "blink.cmp") then
    vim.health.ok("blink.cmp found — completion source available")
  else
    vim.health.warn(
      "blink.cmp not found — completion disabled. Install saghen/blink.cmp and register `pibuf.source`."
    )
  end
end

return M
