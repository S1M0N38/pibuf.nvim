-- Skill discovery for `/skill:<name>` completion.
-- Scans Pi's skill sources, parses SKILL.md frontmatter, returns skills as
-- {name, description}. Discovery runs fresh on each picker open.
--
-- Sources:
--   ~/.agents/skills/*/SKILL.md                       (user-global)
--   {cwd}/.agents/skills/*/SKILL.md                   (project)
--   ~/.pi/agent/skills/ + {cwd}/.pi/skills/           (also loose *.md)
--   ~/.pi/agent/npm/node_modules/*/skills/*/SKILL.md  (packages)

local M = {}

---@class pibuf.Skill
---@field name string
---@field description string

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local c = f:read("*a")
  f:close()
  return c
end

local function is_dir(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == "directory"
end

---Parse YAML-ish frontmatter (`---\nkey: value\n---`); supports plain, quoted,
---and block (`|` / `>`, with `-`/`+` chomping) scalars, folding block content
---to a single line.
---@param content? string
---@return table<string,string>
function M.parse_frontmatter(content)
  if not content or not content:match("^%-%-%-\r?\n") then
    return {}
  end
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    lines[#lines + 1] = line
  end
  if lines[1] ~= "---" then
    return {}
  end
  local fm = {}
  local i = 2
  while i <= #lines and lines[i] ~= "---" do
    local line = lines[i]
    local k, v = line:match("^(%w[%w_-]*):%s*(.*)$")
    if not k then
      i = i + 1
    elseif v:match("^[|>][+-]?$") then
      -- block scalar: gather following indented/blank lines, fold to one line
      local parts = {}
      i = i + 1
      while i <= #lines and lines[i] ~= "---" and (lines[i]:match("^%s") or lines[i] == "") do
        parts[#parts + 1] = lines[i]:match("^%s*(.-)%s*$")
        i = i + 1
      end
      local folded = table.concat(parts, " "):gsub("%s+", " ")
      folded = folded:gsub("^%s", ""):gsub("%s$", "")
      if folded ~= "" then
        fm[k] = folded
      end
    else
      -- plain scalar: strip quotes and surrounding whitespace
      v = v:match('^"(.*)"$') or v:match("^'(.*)'$") or v
      v = v:gsub("^%s+", ""):gsub("%s+$", "")
      if v ~= "" then
        fm[k] = v
      end
      i = i + 1
    end
  end
  return fm
end

---Read one skill file and extract {name, description} from its frontmatter.
---`fallback_name` is used when the frontmatter has no `name` field.
---@param path string absolute path to the SKILL.md / .md file
---@param fallback_name? string
---@return pibuf.Skill?
function M.read_skill_file(path, fallback_name)
  local content = read_file(path)
  if not content then
    return nil
  end
  local fm = M.parse_frontmatter(content)
  if not fm.description then
    return nil
  end
  return { name = fm.name or fallback_name or "", description = fm.description }
end

---Scan a directory for skills.
---@param dir string absolute path
---@param allow_root_md boolean also accept loose `*.md` files
---@return pibuf.Skill[]
function M.scan_dir(dir, allow_root_md)
  local results = {}
  if not is_dir(dir) then
    return results
  end
  for name, type in vim.fs.dir(dir) do
    if type == "directory" then
      local s = M.read_skill_file(dir .. "/" .. name .. "/SKILL.md", name)
      if s then
        results[#results + 1] = s
      end
    elseif allow_root_md and name:match("%.md$") then
      local s = M.read_skill_file(dir .. "/" .. name, name:gsub("%.md$", ""))
      if s then
        results[#results + 1] = s
      end
    end
  end
  return results
end

---Scan package skills: `~/.pi/agent/npm/node_modules/*/skills/*/SKILL.md`.
---@return pibuf.Skill[]
function M.scan_packages()
  local results = {}
  local home = vim.env.HOME or ""
  local base = home .. "/.pi/agent/npm/node_modules"
  if not is_dir(base) then
    return results
  end
  local globs = vim.fn.glob(base .. "/*/skills/*/SKILL.md", false, true)
  if type(globs) == "string" then
    globs = (globs == "" and {} or { globs })
  end
  for _, path in ipairs(globs) do
    local fallback = vim.fs.basename(vim.fs.dirname(path))
    local s = M.read_skill_file(path, fallback)
    if s then
      results[#results + 1] = s
    end
  end
  return results
end

---Discover all skills for a project cwd, deduped by name.
---@param cwd string
---@return pibuf.Skill[]
function M.discover(cwd)
  local home = vim.env.HOME or ""
  local dirs = {
    { dir = home .. "/.agents/skills", root_md = false },
    { dir = cwd .. "/.agents/skills", root_md = false },
    { dir = home .. "/.pi/agent/skills", root_md = true },
    { dir = cwd .. "/.pi/skills", root_md = true },
  }
  local skills, seen = {}, {}
  local function add(s)
    if s.name and s.name ~= "" and not seen[s.name] then
      seen[s.name] = true
      skills[#skills + 1] = s
    end
  end
  for _, entry in ipairs(dirs) do
    for _, s in ipairs(M.scan_dir(entry.dir, entry.root_md)) do
      add(s)
    end
  end
  for _, s in ipairs(M.scan_packages()) do
    add(s)
  end
  return skills
end

return M
