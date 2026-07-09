-- pibuf.nvim: picker-backed prompt editing for the Pi coding agent.
-- Detects Pi's external-editor temp files (filetype `pi`) and installs two
-- buffer-local pickers powered by snacks.nvim.

local M = {}

local augroup = vim.api.nvim_create_augroup("pibuf", { clear = true })

local function activate()
  -- Clear first so repeated setup() calls never stack handlers.
  vim.api.nvim_clear_autocmds({ group = augroup })

  local tmp = vim.uv.os_tmpdir()
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = augroup,
    pattern = {
      vim.fs.joinpath(tmp, "pi-editor-*.pi.md"),
      vim.fs.joinpath(tmp, "pi-extension-editor-*.md"),
    },
    callback = function(args)
      vim.bo[args.buf].filetype = "pi"
      -- land at the end of the prompt and start inserting
      vim.schedule(function()
        local win = vim.fn.bufwinid(args.buf)
        if win == -1 then
          return
        end
        vim.api.nvim_win_call(win, function()
          vim.cmd("keepjumps normal! G")
        end)
        vim.cmd("startinsert!")
      end)
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "pi",
    callback = function(args)
      local Picker = require("pibuf.picker")
      vim.keymap.set({ "i", "n" }, "<C-f>", function()
        Picker.files(args.buf)
      end, { buffer = args.buf, silent = true, desc = "pibuf: insert @file" })
      vim.keymap.set({ "i", "n" }, "<C-s>", function()
        Picker.skills(args.buf)
      end, { buffer = args.buf, silent = true, desc = "pibuf: insert /skill:" })
    end,
  })
end

---Detect `pi` buffers and install the picker keymaps.
function M.setup()
  activate()
end

return M
