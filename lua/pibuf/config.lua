---@class pibuf.Config
---@field files? pibuf.FilesConfig
---@field skills? pibuf.SkillsConfig
---@field winbar? pibuf.WinbarConfig
---@field guard? pibuf.GuardConfig

---@class pibuf.FilesConfig
---@field max_results integer max project-wide fuzzy results (default 50)

---@class pibuf.SkillsConfig
---@field extra_paths string[] extra dirs to scan for skills
---@field manifest? string env var name pointing at a skills manifest (forward-compat seam)

---@class pibuf.WinbarConfig
---@field enabled boolean show the send/cancel hint in the winbar (default true)

---@class pibuf.GuardConfig
---@field unwritten boolean warn on BufWinLeave with unsaved changes (default true)

local M = {}

local defaults = {
  files = { max_results = 50 },
  skills = { extra_paths = {}, manifest = "PI_SKILLS_MANIFEST" },
  winbar = { enabled = true },
  guard = { unwritten = true },
}

-- Active config (deepcopy of defaults so the defaults are never mutated).
local config = vim.deepcopy(defaults)

-- Access config values directly: Config.files, Config.winbar, ...
setmetatable(M, {
  __index = function(_, key)
    return config[key]
  end,
})

-- Created at module load — always available, even before setup().
M.augroup = vim.api.nvim_create_augroup("pibuf", { clear = true })

---Extend the defaults with user options.
---@param opts? pibuf.Config plugin options
function M.setup(opts)
  config = vim.tbl_deep_extend("force", {}, vim.deepcopy(defaults), opts or {})
end

return M
