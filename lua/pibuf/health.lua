local M = {}

local config = require("pibuf.config")

---Health check called by `:checkhealth pibuf`.
function M.check()
  vim.health.start("pibuf.nvim")

  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim >= 0.12")
  else
    vim.health.error("Neovim >= 0.12 is required")
  end

  -- The picker enum is validated at setup(); here we only confirm the chosen
  -- upstream is installed. Warn (not error): the user may install it later.
  local picker = config.picker
  local upstream = config.PICKERS[picker]
  local supported = vim.tbl_keys(config.PICKERS)
  table.sort(supported)
  if pcall(require, upstream) then
    vim.health.ok(("configured picker '%s' found — file/skill pickers available"):format(picker))
  else
    vim.health.warn(
      ("configured picker '%s' not found — pickers disabled"):format(picker),
      ("install %s (supported: %s)"):format(upstream, table.concat(supported, ", "))
    )
  end
end

return M
