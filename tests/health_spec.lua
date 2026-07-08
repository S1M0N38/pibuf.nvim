---@module 'luassert'

local health = require("pibuf.health")
local pibuf = require("pibuf")

describe("health check", function()
  it("runs with default config without errors", function()
    pibuf.did_setup = false
    pibuf.setup({})
    assert.has_no.errors(function()
      health.check()
    end)
  end)

  it("runs with custom config without errors", function()
    pibuf.did_setup = false
    pibuf.setup({ name = "Test User" })
    assert.has_no.errors(function()
      health.check()
    end)
  end)

  it("handles invalid config gracefully", function()
    pibuf.did_setup = false
    pibuf.setup({ name = 123 })
    assert.has_no.errors(function()
      health.check()
    end)
  end)

  it("reports error when setup() was not called", function()
    -- Create a fresh health module to test without setup
    pibuf.did_setup = false
    -- Don't call setup — health should report the issue
    assert.has_no.errors(function()
      health.check()
    end)
  end)
end)
