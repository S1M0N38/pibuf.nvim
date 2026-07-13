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
---@param opts? { picker?: string }
function M.setup(opts)
  opts = opts or {}
  local p = opts.picker
  if p ~= nil and M.PICKERS[p] == nil then
    error(("pibuf: unknown picker %q (want one of snacks, telescope, fzf-lua, mini.pick)"):format(p))
  end
  if p then
    M.picker = p
  end
end

return M
