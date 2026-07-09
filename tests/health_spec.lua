---@module 'luassert'

local health = require("pibuf.health")

describe("health check", function()
  it("runs without errors", function()
    assert.has_no.errors(function()
      health.check()
    end)
  end)
end)
