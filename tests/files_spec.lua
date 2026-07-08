---@module 'luassert'

local files = require("pibuf.files")

local cwd ---@type string temp project root

before_each(function()
  cwd = vim.fs.joinpath(vim.uv.os_tmpdir(), "pibuf-files-" .. tostring(vim.uv.hrtime()))
  vim.fn.mkdir(cwd, "p")
  -- tree:
  --   main.lua
  --   README.md
  --   .hidden (skipped)
  --   node_modules/skip.js (skipped)
  --   src/utils.lua
  --   src/utils_test.lua
  vim.fn.writefile({ "-- main" }, cwd .. "/main.lua")
  vim.fn.writefile({ "# readme" }, cwd .. "/README.md")
  vim.fn.writefile({ "hidden" }, cwd .. "/.hidden")
  vim.fn.mkdir(cwd .. "/node_modules")
  vim.fn.writefile({ "skip" }, cwd .. "/node_modules/skip.js")
  vim.fn.mkdir(cwd .. "/src")
  vim.fn.writefile({ "local utils" }, cwd .. "/src/utils.lua")
  vim.fn.writefile({ "tests" }, cwd .. "/src/utils_test.lua")
end)

after_each(function()
  vim.fn.delete(cwd, "rf")
end)

-- map path -> is_dir for membership/type checks
local function set(cands)
  local m = {}
  for _, c in ipairs(cands) do
    m[c.path] = c.is_dir
  end
  return m
end

describe("files.candidates dir-scoped", function()
  it("base empty lists top-level entries (no hidden/junk)", function()
    local got = set(files.candidates(cwd, ""))
    assert.is_true(got["src"]) -- dir
    assert.is_false(got["main.lua"]) -- file
    assert.is_false(got["README.md"]) -- file
    assert.is_nil(got[".hidden"])
    assert.is_nil(got["node_modules"])
  end)

  it("base with trailing slash lists the subdir", function()
    local got = set(files.candidates(cwd, "src/"))
    assert.is_false(got["src/utils.lua"])
    assert.is_false(got["src/utils_test.lua"])
  end)

  it("base with prefix filters the subdir", function()
    local got = set(files.candidates(cwd, "src/utils"))
    assert.is_false(got["src/utils.lua"])
    assert.is_false(got["src/utils_test.lua"])
    assert.is_nil(got["src/main.lua"])
  end)

  it("produces single-slash relpaths (no //)", function()
    for _, c in ipairs(files.candidates(cwd, "src/")) do
      assert.is_nil(c.path:match("//"))
    end
  end)

  it("nonexistent subdir returns empty", function()
    assert.same({}, files.candidates(cwd, "nope/"))
  end)

  it("dirs sort before files", function()
    vim.fn.mkdir(cwd .. "/zzzdir")
    local got = files.candidates(cwd, "")
    -- find the last dir index and the first file index
    local last_dir, first_file = 0, #got + 1
    for i, c in ipairs(got) do
      if c.is_dir then
        last_dir = i
      elseif i < first_file then
        first_file = i
      end
    end
    assert.is_true(last_dir < first_file)
  end)
end)

describe("files.candidates project-wide (fd)", function()
  it("substring match across the project", function()
    local got = set(files.candidates(cwd, "util"))
    assert.is_false(got["src/utils.lua"])
    assert.is_false(got["src/utils_test.lua"])
  end)

  it("matches a directory name", function()
    local got = set(files.candidates(cwd, "src"))
    assert.is_true(got["src"]) -- the dir itself
    assert.is_false(got["src/utils.lua"])
  end)

  it("excludes junk dirs from the search", function()
    local got = set(files.candidates(cwd, "skip"))
    assert.is_nil(got["node_modules/skip.js"])
  end)

  it("no matches returns empty", function()
    assert.same({}, files.candidates(cwd, "zzznotfound"))
  end)
end)

describe("files.list_dir", function()
  it("respects the cap", function()
    local got = files.list_dir(cwd, "", "", 1)
    assert.are.equal(1, #got)
  end)
end)
