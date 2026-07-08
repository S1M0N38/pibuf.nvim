---@class pibuf.Util
local M = {}

local TITLE = "pibuf.nvim"

---Send a notification with plugin title, scheduled to avoid fast-event issues.
---@param msg string|table message to display
---@param level? integer vim.log.levels value
function M.notify(msg, level)
  msg = type(msg) == "table" and table.concat(msg --[[@as table]], "\n") or msg --[[@as string]]
  vim.schedule(function()
    vim.notify(msg --[[@as string]], level or vim.log.levels.INFO, { title = TITLE })
  end)
end

---@param msg string
function M.info(msg)
  M.notify(msg, vim.log.levels.INFO)
end

---@param msg string
function M.warn(msg)
  M.notify(msg, vim.log.levels.WARN)
end

---@param msg string
function M.error(msg)
  M.notify(msg, vim.log.levels.ERROR)
end

---Read a file's full contents synchronously.
---@param path string
---@return string?
function M.read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local c = f:read("*a")
  f:close()
  return c
end

---@param path string
---@return boolean
function M.is_dir(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == "directory"
end

---@return boolean
function M.has_fd()
  return vim.fn.executable("fd") == 1
end

---Snapshot the project cwd into a buffer-local variable.
---Defends against `:cd` changing the cwd mid-session: file and skill
---completion stay scoped to the project Pi launched the editor in.
---@param buf integer
function M.snapshot_cwd(buf)
  vim.b[buf].pibuf_cwd = vim.fn.getcwd()
end

---Get the snapshotted cwd for a buffer, falling back to the current cwd.
---@param buf integer
---@return string
function M.get_cwd(buf)
  return vim.b[buf].pibuf_cwd or vim.fn.getcwd()
end

return M
