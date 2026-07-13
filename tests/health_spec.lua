---@module 'luassert'

local health = require("pibuf.health")
local config = require("pibuf.config")

-- `:checkhealth` reports via vim.health, which prints; we assert it runs and
-- that the installed-check branches the right way for the configured picker.
-- We stub `vim.health` to capture ok/warn/error calls instead of printing.

local saved_picker, saved_loaded_snacks
local saved_ok, saved_warn, saved_error, saved_start

before_each(function()
  saved_picker = config.picker
  saved_loaded_snacks = package.loaded["snacks"]
  saved_ok = vim.health.ok
  saved_warn = vim.health.warn
  saved_error = vim.health.error
  saved_start = vim.health.start
end)

after_each(function()
  config.picker = saved_picker
  package.loaded["snacks"] = saved_loaded_snacks
  vim.health.ok = saved_ok
  vim.health.warn = saved_warn
  vim.health.error = saved_error
  vim.health.start = saved_start
end)

local function stub_health()
  local calls = { ok = {}, warn = {}, error = {} }
  vim.health.start = function() end
  vim.health.ok = function(msg)
    table.insert(calls.ok, msg)
  end
  vim.health.warn = function(msg, hint)
    table.insert(calls.warn, { msg = msg, hint = hint })
  end
  vim.health.error = function(msg)
    table.insert(calls.error, msg)
  end
  return calls
end

describe("health check", function()
  it("runs without errors", function()
    stub_health()
    assert.has_no.errors(function()
      health.check()
    end)
  end)

  it("reports ok when the configured upstream is installed", function()
    config.picker = "snacks"
    package.loaded["snacks"] = {}
    local calls = stub_health()
    health.check()
    local joined = table.concat(calls.ok, " ")
    assert.matches("configured picker 'snacks' found", joined)
    assert.are.equal(0, #calls.warn)
  end)

  it("warns (not errors) when the configured upstream is missing", function()
    config.picker = "snacks"
    package.loaded["snacks"] = nil -- simulate snacks not installed
    -- point the enum at a module that will never resolve regardless
    local saved_upstream = config.PICKERS["snacks"]
    config.PICKERS["snacks"] = "pibuf.__definitely_not_installed"
    local calls = stub_health()
    health.check()
    config.PICKERS["snacks"] = saved_upstream

    assert.are.equal(0, #calls.error)
    assert.are.equal(1, #calls.warn)
    assert.matches("configured picker 'snacks' not found", calls.warn[1].msg)
    assert.matches("snacks", calls.warn[1].hint)
  end)
end)
