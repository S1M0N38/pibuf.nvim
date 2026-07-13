-- mini.pick adapter — wraps `MiniPick.builtin.files` and `MiniPick.start`
-- behind the pibuf contract. Dumb: only `files(cwd, on_select)` and
-- `items(items, opts, on_select)`. mini.pick is synchronous: `start`/`files`
-- return the chosen item (or nil on cancel).

local M = {}

---Open mini.pick's file picker scoped to `cwd` (gitignore-aware via rg/fd/git).
---@param cwd string absolute
---@param on_select fun(path: string) called once with the chosen path (cwd-relative)
function M.files(cwd, on_select)
  local ok, MiniPick = pcall(require, "mini.pick")
  if not ok then
    return
  end
  local item = MiniPick.builtin.files({}, {
    source = { cwd = cwd, name = " pibuf: @file " },
  })
  if item ~= nil then
    on_select(item)
  end
end

---Open a mini.pick picker over an in-memory list (skills), with a markdown
---preview of each item's `preview` body.
---@param items pibuf.PickItem[]
---@param opts { title: string }
---@param on_select fun(value: string) called once with the chosen item.value
function M.items(items, opts, on_select)
  local ok, MiniPick = pcall(require, "mini.pick")
  if not ok then
    return
  end
  local values = {}
  local preview_map = {}
  for _, it in ipairs(items) do
    values[#values + 1] = it.value
    preview_map[it.value] = it.preview or ""
  end
  local item = MiniPick.start({
    source = {
      items = values,
      name = opts.title,
      preview = function(buf_id, entry)
        local lines = vim.split(preview_map[entry] or "", "\n", { plain = true })
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
        vim.bo[buf_id].filetype = "markdown"
      end,
    },
  })
  if item ~= nil then
    on_select(item)
  end
end

return M
