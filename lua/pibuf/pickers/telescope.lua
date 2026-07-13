-- telescope.nvim adapter — wraps `telescope.builtin` / `telescope.pickers`
-- behind the pibuf contract. Like every adapter: dumb, no formatting/cursor
-- logic, only `files(cwd, on_select)` and `items(items, opts, on_select)`.

local M = {}

---@return table? actions
local function telescope_actions()
  local ok, actions = pcall(require, "telescope.actions")
  return ok and actions or nil
end

---Open telescope's file picker scoped to `cwd`.
---@param cwd string absolute
---@param on_select fun(path: string) called once with the chosen path (cwd-relative)
function M.files(cwd, on_select)
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    return
  end
  local actions = telescope_actions()
  if not actions then
    return
  end
  builtin.find_files({
    cwd = cwd,
    attach_mappings = function(prompt_bufnr, _map)
      actions.select_default:replace(function()
        local entry = require("telescope.actions.state").get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry then
          return
        end
        on_select(entry.value)
      end)
      return true
    end,
  })
end

---Open a telescope picker over an in-memory list (skills), with a markdown
---preview of each item's `preview` body.
---@param items pibuf.PickItem[]
---@param opts { title: string }
---@param on_select fun(value: string) called once with the chosen item.value
function M.items(items, opts, on_select)
  local ok_pickers, pickers = pcall(require, "telescope.pickers")
  if not ok_pickers then
    return
  end
  local finders = require("telescope.finders")
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values
  local actions = telescope_actions()
  if not actions then
    return
  end

  local entry_maker = function(item)
    return {
      value = item.value,
      display = item.value,
      ordinal = item.value,
      preview = item.preview,
    }
  end

  pickers
    .new({}, {
      prompt_title = opts.title,
      finder = finders.new_table({ results = items, entry_maker = entry_maker }),
      previewer = previewers.new_buffer_previewer({
        title = opts.title,
        define_preview = function(self, entry, _status)
          local lines = vim.split(entry.preview or "", "\n", { plain = true })
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.bo[self.state.bufnr].filetype = "markdown"
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _map)
        actions.select_default:replace(function()
          local entry = require("telescope.actions.state").get_selected_entry()
          actions.close(prompt_bufnr)
          if not entry then
            return
          end
          on_select(entry.value)
        end)
        return true
      end,
    })
    :find()
end

return M
