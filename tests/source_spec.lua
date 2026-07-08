---@module 'luassert'

local classify = require("pibuf.source").classify

describe("source.classify", function()
  describe("file context (@)", function()
    it("@ at start of line -> file, col 0", function()
      assert.same({ kind = "file", col = 0 }, classify("@src", 4))
    end)

    it("@ preceded by whitespace -> file at @ col", function()
      assert.same({ kind = "file", col = 1 }, classify(" @src", 5))
    end)

    it("mid-path slashes do not break the mention", function()
      assert.same({ kind = "file", col = 0 }, classify("@src/ut", 7))
    end)

    it("bare @ -> file, col 0", function()
      assert.same({ kind = "file", col = 0 }, classify("@", 1))
    end)

    it("@ mid-token (email) -> nil", function()
      assert.is_nil(classify("foo@bar", 7))
    end)
  end)

  describe("skill context (/)", function()
    it("/ at start of line -> skill, col 0", function()
      assert.same({ kind = "skill", col = 0 }, classify("/skill", 6))
    end)

    it("/ preceded by whitespace -> skill at / col", function()
      assert.same({ kind = "skill", col = 4 }, classify("foo /skill", 10))
    end)

    it("bare / -> skill, col 0", function()
      assert.same({ kind = "skill", col = 0 }, classify("/", 1))
    end)

    it("/ not at token start -> nil", function()
      assert.is_nil(classify("a/b", 3))
    end)
  end)

  describe("no context", function()
    it("plain text -> nil", function()
      assert.is_nil(classify("plain text", 10))
    end)

    it("empty line -> nil", function()
      assert.is_nil(classify("", 0))
    end)

    it("word with no trigger -> nil", function()
      assert.is_nil(classify("foo", 3))
    end)
  end)
end)
