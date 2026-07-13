-- fzf-lua adapter — wraps `fzf-lua.files` and `fzf-lua.fzf_exec` behind the
-- pibuf contract. Dumb: only `files(cwd, on_select)` and
-- `items(items, opts, on_select)`.

local M = {}

---Run a fzf-lua "default" action: pick the first selected entry, or bail.
---@param selected string[]? entries fzf-lua passed to the action
---@param on_select fun(value: string)
local function default_action(selected, on_select)
  if not selected or not selected[1] then
    return
  end
  on_select(selected[1])
end

---Open fzf-lua's file picker scoped to `cwd`.
---@param cwd string absolute
---@param on_select fun(path: string) called once with the chosen path (cwd-relative)
function M.files(cwd, on_select)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    return
  end
  fzf.files({
    cwd = cwd,
    actions = {
      ["default"] = function(selected)
        default_action(selected, on_select)
      end,
    },
  })
end

---Open a fzf-lua picker over an in-memory list (skills), with a markdown
---preview of each item's `preview` body.
---@param items pibuf.PickItem[]
---@param opts { title: string }
---@param on_select fun(value: string) called once with the chosen item.value
function M.items(items, opts, on_select)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    return
  end
  -- fzf-lua lists are plain strings; keep a value→preview map so the preview
  -- function can render the description for the highlighted entry.
  local entries = {}
  local preview_map = {}
  for _, it in ipairs(items) do
    entries[#entries + 1] = it.value
    preview_map[it.value] = it.preview or ""
  end
  fzf.fzf_exec(entries, {
    prompt = opts.title,
    actions = {
      ["default"] = function(selected)
        default_action(selected, on_select)
      end,
    },
    preview = function(args)
      return preview_map[args and args[1] or ""]
    end,
  })
end

return M
