---blink.cmp source for Pi buffers.
---
---One source, two contexts dispatched by a backward scan from the cursor:
---  * `@` starting a token -> file mention completion (pibuf.files)
---  * `/` starting a token  -> skill reference completion (pibuf.skills)
---
---blink does the fuzzy filtering; this source returns candidates with
---`textEdit` ranges (0-indexed, end-exclusive) spanning the `@`/`/` prefix.
local M = {}

local Kind = vim.lsp.protocol.CompletionItemKind

---@class pibuf.Context
---@field kind "file"|"skill"
---@field col integer 0-indexed byte column of the trigger (`@` or `/`)

---Classify the cursor position on `line` by scanning backward over the
---current whitespace-delimited token.
---@param line string full line text
---@param cursor_col integer 0-indexed byte column of the cursor
---@return pibuf.Context?
function M.classify(line, cursor_col)
  local before = line:sub(1, cursor_col) -- text before the cursor
  local i = #before
  while i >= 1 do
    local ch = before:sub(i, i)
    if ch == " " or ch == "\t" then
      break
    end
    if ch == "@" then
      -- `@` must start a token (BOL or preceded by whitespace)
      local at_0 = i - 1
      if at_0 == 0 or before:sub(at_0, at_0):match("%s") then
        return { kind = "file", col = at_0 }
      end
      return nil -- `@` mid-token (e.g. an email) -> no completion
    end
    i = i - 1
  end
  -- no `@` in the token; `i` is now the 0-indexed start of the token
  -- (BOL, or the 1-indexed position of the breaking whitespace).
  local token_start_0 = i
  if token_start_0 < #before and before:sub(token_start_0 + 1, token_start_0 + 1) == "/" then
    return { kind = "skill", col = token_start_0 }
  end
  return nil
end

---Build a 0-indexed, end-exclusive LSP range replacing [col+1, cursor_col).
---@param row integer 1-indexed cursor row
---@param col integer 0-indexed trigger column
---@param cursor_col integer 0-indexed cursor column
---@return lsp.Range
local function range(row, col, cursor_col)
  return {
    start = { line = row - 1, character = col + 1 },
    ["end"] = { line = row - 1, character = cursor_col },
  }
end

---Build file-mention completion items.
---@param bufnr integer
---@param line string
---@param row integer
---@param at_col integer 0-indexed column of `@`
---@param cursor_col integer
---@return table[] items  lsp.CompletionItem[] (blink filters by filterText/label)
function M.file_items(bufnr, line, row, at_col, cursor_col)
  local cwd = require("pibuf.util").get_cwd(bufnr)
  local base = line:sub(at_col + 2, cursor_col) -- text after `@`, before cursor
  local cands = require("pibuf.files").candidates(cwd, base)
  local r = range(row, at_col, cursor_col)
  local items = {}
  for _, c in ipairs(cands) do
    local insert = c.is_dir and (c.path .. "/") or c.path
    items[#items + 1] = {
      label = insert,
      filterText = c.path,
      sortText = (c.is_dir and "1" or "2") .. c.path:lower(),
      kind = c.is_dir and Kind.Folder or Kind.File,
      textEdit = { newText = insert, range = r },
    }
  end
  return items
end

---Build skill-reference completion items (`/skill:<name>`).
---@param bufnr integer
---@param row integer
---@param slash_col integer 0-indexed column of `/`
---@param cursor_col integer
---@return table[] items  lsp.CompletionItem[]
function M.skill_items(bufnr, row, slash_col, cursor_col)
  local skills = require("pibuf.skills").get(bufnr)
  local r = range(row, slash_col, cursor_col)
  local items = {}
  for _, s in ipairs(skills) do
    local text = "skill:" .. s.name
    items[#items + 1] = {
      label = text,
      filterText = text,
      detail = s.description,
      kind = Kind.Keyword,
      textEdit = { newText = text, range = r },
    }
  end
  return items
end

---@param opts? table source opts (unused for now)
---@return pibuf.Source
function M.new(opts)
  local self = setmetatable({}, { __index = M })
  self.opts = opts or {}
  return self --[[@as pibuf.Source]]
end

---Gate to Pi buffers only.
function M:enabled()
  return vim.bo.filetype == "pi"
end

function M:get_trigger_characters()
  return { "@", "/" }
end

---@param context table  blink.cmp.Context (line, cursor, bufnr)
---@param callback fun(response?: table)  blink completion callback
function M:get_completions(context, callback)
  local line = context.line
  local row = context.cursor[1]
  local cursor_col = context.cursor[2]
  local ctx = M.classify(line, cursor_col)
  if not ctx then
    return callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
  end
  local items
  if ctx.kind == "file" then
    items = M.file_items(context.bufnr, line, row, ctx.col, cursor_col)
  else
    items = M.skill_items(context.bufnr, row, ctx.col, cursor_col)
  end
  callback({ is_incomplete_forward = true, is_incomplete_backward = false, items = items })
end

return M
