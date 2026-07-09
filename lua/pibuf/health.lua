local M = {}

---Health check called by `:checkhealth pibuf`.
function M.check()
  vim.health.start("pibuf.nvim")

  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim >= 0.12")
  else
    vim.health.error("Neovim >= 0.12 is required")
  end

  if pcall(require, "snacks") then
    vim.health.ok("snacks.nvim found — file/skill pickers available")
  else
    vim.health.error("snacks.nvim not found — pickers disabled. Install folke/snacks.nvim.")
  end
end

return M
