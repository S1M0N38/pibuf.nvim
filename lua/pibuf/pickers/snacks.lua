-- snacks.nvim adapter — wraps `snacks.picker` behind the pibuf contract.
-- Adapters are dumb: they know only `files(cwd, on_select)` and
-- `items(items, opts, on_select)`. No `@`/`/skill:` formatting, no cursor logic,
-- no relpath — that all lives in the dispatcher (`pibuf.pickers.init`).

local M = {}

---Resolve snacks.picker (defense-in-depth; the dispatcher already checked).
---@return table? SnacksPicker
local function snacks_picker()
  local ok, SnacksPicker = pcall(require, "snacks.picker")
  if not ok then
    return nil
  end
  return SnacksPicker
end

---Open the snacks file picker scoped to `cwd`.
---@param cwd string absolute
---@param on_select fun(path: string) called once with the chosen path (cwd-relative)
function M.files(cwd, on_select)
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
      on_select(item.file)
    end,
  })
end

---Open the snacks picker over an in-memory list (skills).
---@param items pibuf.PickItem[]
---@param opts { title: string }
---@param on_select fun(value: string) called once with the chosen item.value
function M.items(items, opts, on_select)
  local SnacksPicker = snacks_picker()
  if not SnacksPicker then
    return
  end
  -- Skills aren't files: `text` format shows the name, the `preview` previewer
  -- renders the description, and a `vertical` layout shrinks the preview.
  local snack_items = {}
  for i, it in ipairs(items) do
    snack_items[i] = {
      text = it.value,
      name = it.value,
      preview = { text = it.preview or "", ft = "markdown" },
    }
  end
  SnacksPicker({
    items = snack_items,
    format = "text",
    preview = "preview",
    layout = "vertical",
    title = opts.title,
    win = { preview = { wo = { wrap = true } } },
    confirm = function(picker, item)
      picker:close()
      if not item or not item.name then
        return
      end
      on_select(item.name)
    end,
  })
end

return M
