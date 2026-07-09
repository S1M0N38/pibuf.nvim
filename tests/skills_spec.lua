---@module 'luassert'

local skills = require("pibuf.skills")

local tmp ---@type string temp skills root, recreated per test

before_each(function()
  tmp = vim.fs.joinpath(vim.uv.os_tmpdir(), "pibuf-skills-" .. tostring(vim.uv.hrtime()))
  vim.fn.mkdir(tmp, "p")
end)

after_each(function()
  vim.fn.delete(tmp, "rf")
end)

local function write(path, content)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(vim.split(content, "\n"), path)
end

describe("skills.parse_frontmatter", function()
  it("parses name + description", function()
    local fm = skills.parse_frontmatter("---\nname: foo\ndescription: bar\n---\nbody")
    assert.are.equal("foo", fm.name)
    assert.are.equal("bar", fm.description)
  end)

  it("strips quotes around values", function()
    local fm = skills.parse_frontmatter("---\nname: \"quoted name\"\ndescription: 'a skill'\n---")
    assert.are.equal("quoted name", fm.name)
    assert.are.equal("a skill", fm.description)
  end)

  it("returns empty table when no frontmatter", function()
    assert.same({}, skills.parse_frontmatter("# title\nno fm"))
  end)

  it("returns empty table for nil input", function()
    assert.same({}, skills.parse_frontmatter(nil))
  end)

  it("ignores leading --- that is not at the very start", function()
    -- a thematic break mid-document is not frontmatter
    assert.same({}, skills.parse_frontmatter("# title\n\n---\nname: foo\n---"))
  end)

  it("folds a literal block scalar (|) to one line", function()
    local fm = skills.parse_frontmatter("---\nname: lit\ndescription: |\n  First line.\n  Second line.\n---")
    assert.are.equal("First line. Second line.", fm.description)
  end)

  it("folds a folded block scalar (>-) to one line", function()
    local fm = skills.parse_frontmatter("---\nname: fold\ndescription: >-\n  One sentence\n  two sentence.\n---")
    assert.are.equal("One sentence two sentence.", fm.description)
  end)

  it("block scalar ends at the next non-indented key", function()
    local fm = skills.parse_frontmatter('---\nname: x\ndescription: >\n  body line\nargument-hint: "<obj>"\n---')
    assert.are.equal("body line", fm.description)
    assert.are.equal("<obj>", fm["argument-hint"])
  end)
end)

describe("skills.scan_dir", function()
  it("reads dir/SKILL.md with frontmatter", function()
    write(tmp .. "/alpha/SKILL.md", "---\nname: alpha\ndescription: Alpha skill\n---\nbody")
    local got = skills.scan_dir(tmp, false)
    assert.are.equal(1, #got)
    assert.are.equal("alpha", got[1].name)
    assert.are.equal("Alpha skill", got[1].description)
  end)

  it("skips SKILL.md without description", function()
    write(tmp .. "/beta/SKILL.md", "---\nname: beta\n---\nbody")
    local got = skills.scan_dir(tmp, false)
    assert.are.equal(0, #got)
  end)

  it("falls back to dir name when name is missing", function()
    write(tmp .. "/gamma/SKILL.md", "---\ndescription: Gamma skill\n---\nbody")
    local got = skills.scan_dir(tmp, false)
    assert.are.equal("gamma", got[1].name)
  end)

  it("with allow_root_md also reads loose .md files", function()
    write(tmp .. "/alpha/SKILL.md", "---\nname: alpha\ndescription: dir skill\n---")
    write(tmp .. "/loose.md", "---\nname: loose\ndescription: loose skill\n---")
    local got = skills.scan_dir(tmp, true)
    local names = {}
    for _, s in ipairs(got) do
      names[s.name] = true
    end
    assert.is_true(names.alpha)
    assert.is_true(names.loose)
  end)

  it("without allow_root_md ignores loose .md files", function()
    write(tmp .. "/loose.md", "---\nname: loose\ndescription: loose skill\n---")
    local got = skills.scan_dir(tmp, false)
    assert.are.equal(0, #got)
  end)

  it("returns empty for a missing directory", function()
    assert.same({}, skills.scan_dir(tmp .. "/nope", false))
  end)
end)

describe("skills.discover", function()
  it("finds a project skill under {cwd}/.agents/skills", function()
    local cwd = tmp
    write(cwd .. "/.agents/skills/myproj/SKILL.md", "---\nname: myproj\ndescription: project skill\n---")
    local got = skills.discover(cwd)
    local found = false
    for _, s in ipairs(got) do
      if s.name == "myproj" then
        found = true
      end
    end
    assert.is_true(found)
  end)
end)
