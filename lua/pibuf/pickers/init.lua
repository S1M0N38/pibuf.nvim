-- pibuf pickers dispatcher: the unified entry point for file/skill picking.
-- Owns cursor capture, `@`/`/skill:` formatting, and relpath resolution; each
-- backend is a dumb adapter in `lua/pibuf/pickers/<name>.lua` that knows only
-- `files(cwd, on_select)` and `items(items, opts, on_select)`.

local M = {}

local config = require("pibuf.config")
local Skills = require("pibuf.skills")

---A pickable item shared across adapters (used by the skills picker).
---@class pibuf.PickItem
---@field value string the value returned on confirm (e.g. a skill name)
---@field preview? string markdown body for the preview pane

-- picker enum value → our adapter module path.
-- `mini.pick` is special: its file is `mini_pick.lua` because Lua's `require`
-- turns `.` into `/`, so a flat file can't carry the dotted name on disk.
M.MODULES = {
  snacks = "pibuf.pickers.snacks",
  telescope = "pibuf.pickers.telescope",
  ["fzf-lua"] = "pibuf.pickers.fzf-lua",
  ["mini.pick"] = "pibuf.pickers.mini_pick",
}

---Resolve the active adapter, or notify and return nil if its upstream is
---missing. The enum is already validated at setup(); here we only confirm the
---upstream plugin is installed (deferred so lazy-load ordering is respected).
---@return table? adapter
local function require_adapter()
  local picker = config.picker
  local upstream = config.PICKERS[picker]
  local ok = pcall(require, upstream)
  if not ok then
    vim.notify(
      ("pibuf: picker %q is not installed. Install %s, or set a different picker in setup()."):format(picker, upstream),
      vim.log.levels.ERROR,
      { title = "pibuf.nvim" }
    )
    return nil
  end
  return require(M.MODULES[picker])
end

---Insert `text` at the captured cursor, then append after it in insert mode.
---@param buf integer
---@param row integer 1-indexed line
---@param col integer 0-indexed byte column
---@param text string
local function insert_at(buf, row, col, text)
  vim.api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, { text })
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    return
  end
  -- `a` appends after the inserted text's last char and enters insert mode,
  -- landing the cursor past it in both mid-line and end-of-line cases.
  vim.api.nvim_win_set_cursor(win, { row, col + #text - 1 })
  vim.api.nvim_feedkeys("a", "n", false)
end

---Open the file picker; insert `@<relpath>` at the cursor on confirm.
---@param buf integer target pi buffer
function M.files(buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local cwd = vim.fn.getcwd()
  local adapter = require_adapter()
  if not adapter then
    return
  end
  adapter.files(cwd, function(path)
    -- Adapters return a path scoped to `cwd` (relative by convention).
    -- `relpath` normalizes any input form; `or path` keeps paths outside cwd.
    vim.schedule(function()
      insert_at(buf, row, col, "@" .. (vim.fs.relpath(cwd, path) or path) .. " ")
    end)
  end)
end

---Open the skills picker; insert `/skill:<name>` at the cursor on confirm.
---@param buf integer target pi buffer
function M.skills(buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local cwd = vim.fn.getcwd()
  local adapter = require_adapter()
  if not adapter then
    return
  end
  local items = vim.tbl_map(function(s)
    return { value = s.name, preview = s.description }
  end, Skills.discover(cwd))
  adapter.items(items, { title = " pibuf: /skill " }, function(value)
    vim.schedule(function()
      insert_at(buf, row, col, "/skill:" .. value .. " ")
    end)
  end)
end

return M
