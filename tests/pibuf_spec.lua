---@module 'luassert'

local pibuf = require("pibuf")
pibuf.setup({})

describe("default options", function()
  it("hello() returns greeting with default name", function()
    assert.are.equal("Hello John Doe", pibuf.hello())
  end)

  it("bye() returns farewell with default name", function()
    assert.are.equal("Bye John Doe", pibuf.bye())
  end)

  it("setup() sets did_setup to true", function()
    assert.is_true(pibuf.did_setup)
  end)
end)

describe("user defined options", function()
  before_each(function()
    -- Reset did_setup to allow re-setup in tests
    pibuf.did_setup = false
    pibuf.setup({ name = "World" })
  end)

  it("hello() returns greeting with custom name", function()
    assert.are.equal("Hello World", pibuf.hello())
  end)

  it("bye() returns farewell with custom name", function()
    assert.are.equal("Bye World", pibuf.bye())
  end)
end)

describe("double setup guard", function()
  it("warns on second setup() call", function()
    pibuf.did_setup = false
    pibuf.setup({ name = "First" })
    -- Second call should not error, just warn
    assert.has_no.errors(function()
      pibuf.setup({ name = "Second" })
    end)
    -- Name should still be "First" since second setup was rejected
    assert.are.equal("Hello First", pibuf.hello())
  end)
end)
