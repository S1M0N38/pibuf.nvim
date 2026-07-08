---@class pibuf.Plugin
local M = {}

M.did_setup = false

local Util = require("pibuf.util")

---Setup the pibuf plugin.
---@param opts? pibuf.Config plugin options
function M.setup(opts)
  if M.did_setup then
    return Util.warn("pibuf.nvim is already setup")
  end
  M.did_setup = true
  require("pibuf.config").setup(opts)
  M.activate()
end

---Does the basename look like a Pi temp file (either editor kind)?
---@param path string
---@return boolean
local function is_pi_tempfile(path)
  local name = vim.fs.basename(path)
  return name:match("^pi%-editor%-.+%.pi%.md$") ~= nil or name:match("^pi%-extension%-editor%-.+%.md$") ~= nil
end

---Set the `pi` filetype on Pi's Ctrl-G temp buffers.
---Primary signal: the specific temp-file basename (anywhere on the path).
---Defensive fallback: any temp file (under os_tmpdir()) when Pi is in the
---parent environment (PI_CODING_AGENT=true) — covers future renames.
local function detect_filetype(ev)
  local path = vim.api.nvim_buf_get_name(ev.buf)
  if path == "" then
    return
  end
  if is_pi_tempfile(path) then
    vim.bo[ev.buf].filetype = "pi"
    return
  end
  if vim.env.PI_CODING_AGENT == "true" then
    local tmp = vim.uv.os_tmpdir()
    if vim.fs.dirname(path) == tmp then
      vim.bo[ev.buf].filetype = "pi"
    end
  end
end

---Show the send/cancel hint in the winbar.
local function set_winbar(buf)
  if not require("pibuf.config").winbar.enabled then
    return
  end
  if vim.api.nvim_win_is_valid(0) and vim.api.nvim_win_get_buf(0) == buf then
    vim.wo[0].winbar = "save & quit to send  ·  :cq to cancel"
  end
end

---Warn when a modified Pi buffer is closed without writing (changes lost).
local function attach_guard(buf)
  if not require("pibuf.config").guard.unwritten then
    return
  end
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = require("pibuf.config").augroup,
    buffer = buf,
    callback = function(ev)
      if vim.bo[ev.buf].modified then
        Util.warn("Pi buffer closed with unsaved changes — edits were not sent")
      end
    end,
  })
end

---Register activation + lifecycle autocmds. Idempotent via setup() guard.
function M.activate()
  local Config = require("pibuf.config")
  -- Clear any prior autocmds so re-setup (e.g. in tests) doesn't stack them.
  vim.api.nvim_clear_autocmds({ group = Config.augroup })

  -- filetype detection (before FileType wiring)
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = Config.augroup,
    callback = detect_filetype,
  })

  -- per-buffer setup once filetype=pi is set
  vim.api.nvim_create_autocmd("FileType", {
    group = Config.augroup,
    pattern = "pi",
    callback = function(ev)
      Util.snapshot_cwd(ev.buf)
      require("pibuf.skills").refresh(ev.buf)
      set_winbar(ev.buf)
      attach_guard(ev.buf)
    end,
  })
end

---Refresh the skill cache for the current buffer.
function M.refresh()
  require("pibuf.skills").refresh(0)
  Util.info("pibuf skills refreshed")
end

return M
