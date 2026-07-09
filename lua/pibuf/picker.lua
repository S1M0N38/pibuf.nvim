-- snacks.nvim pickers for `pi` buffers.
--   <C-f>  file picker  -> insert `@<relpath>`
--   <C-s>  skills picker -> insert `/skill:<name>`
-- snacks loads lazily; this module loads without it, only a picker needs it.

local M = {}

local Skills = require("pibuf.skills")

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

---Resolve snacks.picker, or notify and return nil if snacks is missing.
local function snacks_picker()
  local ok, SnacksPicker = pcall(require, "snacks.picker")
  if not ok then
    vim.notify("pibuf needs snacks.nvim for its picker. Install folke/snacks.nvim.",
      vim.log.levels.ERROR, { title = "pibuf.nvim" })
  end
  return SnacksPicker
end

---Open the file picker; insert `@<relpath>` at the cursor.
---@param buf integer
function M.files(buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local cwd = vim.fn.getcwd()
  local SnacksPicker = snacks_picker()
  if not SnacksPicker then
    return
  end
  SnacksPicker.files({
    cwd = cwd,
    title = " pibuf: @file ",
    confirm = function(picker, item)
      picker:close()
      if not item or not item.file then
        return
      end
      local rel = vim.fs.relpath(cwd, item.file) or item.file
      vim.schedule(function()
        insert_at(buf, row, col, "@" .. rel .. " ")
      end)
    end,
  })
end

---Open the skills picker; insert `/skill:<name>` at the cursor.
---@param buf integer
function M.skills(buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local SnacksPicker = snacks_picker()
  if not SnacksPicker then
    return
  end
  -- Skills aren't files: `text` format shows the name, the `preview` previewer
  -- renders the description, and a `vertical` layout shrinks the preview.
  local cwd = vim.fn.getcwd()
  local items = {}
  for _, s in ipairs(Skills.discover(cwd)) do
    items[#items + 1] = {
      text = s.name,
      name = s.name,
      preview = { text = s.description or "", ft = "markdown" },
    }
  end
  SnacksPicker({
    items = items,
    format = "text",
    preview = "preview",
    layout = "vertical",
    title = " pibuf: /skill ",
    win = { preview = { wo = { wrap = true } } },
    confirm = function(picker, item)
      picker:close()
      if not item or not item.name then
        return
      end
      vim.schedule(function()
        insert_at(buf, row, col, "/skill:" .. item.name .. " ")
      end)
    end,
  })
end

return M
