---@module 'luassert'

local health = require("pibuf.health")
local pibuf = require("pibuf")

describe("health check", function()
  it("runs without errors when setup was called", function()
    pibuf.did_setup = false
    pibuf.setup({})
    assert.has_no.errors(function()
      health.check()
    end)
  end)

  it("runs without errors when setup was not called", function()
    pibuf.did_setup = false
    assert.has_no.errors(function()
      health.check()
    end)
  end)
end)
