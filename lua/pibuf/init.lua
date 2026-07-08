---@class Pibuf.Plugin
local M = {}

M.did_setup = false

---Setup the pibuf plugin
---@param opts? Pibuf.UserOptions plugin options
function M.setup(opts)
  if M.did_setup then
    local Util = require("pibuf.util")
    return Util.warn("pibuf.nvim is already setup")
  end
  M.did_setup = true
  require("pibuf.config").setup(opts)
end

---Say hello to the user
---@return string msg greeting message
function M.hello()
  local Config = require("pibuf.config")
  local str = "Hello " .. Config.name
  local Util = require("pibuf.util")
  Util.info(str)
  return str
end

---Say bye to the user
---@return string msg farewell message
function M.bye()
  local Config = require("pibuf.config")
  local str = "Bye " .. Config.name
  local Util = require("pibuf.util")
  Util.info(str)
  return str
end

return M
