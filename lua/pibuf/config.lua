-- pibuf config: the picker enum source of truth.
-- `setup({ picker = "<name>" })` validates against PICKERS; the active value
-- lives in `config.picker` (default "snacks").

local M = {}

-- enum: picker name → upstream require name (single source of truth)
M.PICKERS = {
  snacks = "snacks",
  telescope = "telescope",
  ["fzf-lua"] = "fzf-lua",
  ["mini.pick"] = "mini.pick",
}

-- default preserves the pre-multi-picker behavior (non-breaking)
M.picker = "snacks"

---Validate and apply user options.
---An unknown `picker` is a soft error: an ERROR notification is scheduled and
---the previously-configured (default `"snacks"`) picker is kept, so a typo
---never stops the plugin from loading.
---@param opts? { picker?: string }
function M.setup(opts)
  opts = opts or {}
  local p = opts.picker
  if p ~= nil and M.PICKERS[p] == nil then
    vim.schedule(function()
      vim.notify(
        ("pibuf: unknown picker %q (want one of snacks, telescope, fzf-lua, mini.pick); keeping %q"):format(p, M.picker),
        vim.log.levels.ERROR,
        { title = "pibuf.nvim" }
      )
    end)
    return
  end
  if p then
    M.picker = p
  end
end

return M
