---Skill discovery for the `/skill:<name>` completion.
---
---Scans Pi's four skill sources, parses `SKILL.md` frontmatter, caches per
---project cwd, and exposes a forward-compat manifest-consumption seam.
---
---Sources (best-effort; ~95% accuracy, see design doc):
---  1. `~/.agents/skills/*/SKILL.md`
---  2. `{cwd}/.agents/skills/*/SKILL.md`
---  3. `~/.pi/agent/skills/` + `{cwd}/.pi/skills/` (also allow single `.md`)
---  4. package skills: `~/.pi/agent/npm/node_modules/*/skills/*/SKILL.md`
local M = {}

local Util = require("pibuf.util")

---@class pibuf.Skill
---@field name string
---@field description string

-- Cache keyed by the snapshotted cwd. nil/empty => needs (re)discovery.
local state = { cwd = nil, skills = nil }

---Parse YAML-ish frontmatter (`---\nkey: value\n---`) from a SKILL.md body.
---Only treats the leading block as frontmatter (must start with `---`).
---Handles plain scalars, quoted scalars, and block scalars (`|`, `>`, with
---optional `-`/`+` chomping), folding block content to a single line.
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
  local content = Util.read_file(path)
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
---@param allow_root_md boolean also accept loose `*.md` files (sources 3)
---@return pibuf.Skill[]
function M.scan_dir(dir, allow_root_md)
  local results = {}
  if not Util.is_dir(dir) then
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
  if not Util.is_dir(base) then
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

---Forward-compat seam: if a manifest is env-pointed, parse and prefer it over
---the filesystem scan. NOT built out — a future Pi extension will populate the
---manifest. Format is tentative: `{ skills = { {name=, description=}, ... } }`
---or a bare list. Returns nil when no manifest is set/readable.
---@return pibuf.Skill[]?
function M.consume_manifest()
  local env_name = require("pibuf.config").skills.manifest
  if not env_name then
    return nil
  end
  local path = vim.env[env_name]
  if not path or path == "" then
    return nil
  end
  local content = Util.read_file(path)
  if not content then
    return nil
  end
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return nil
  end
  local list = data.skills or data
  if type(list) ~= "table" then
    return nil
  end
  local skills = {}
  for _, s in ipairs(list) do
    if type(s) == "table" and s.name and s.description then
      skills[#skills + 1] = { name = s.name, description = s.description }
    end
  end
  return #skills > 0 and skills or nil
end

---Discover all skills for a given project cwd, deduped by name.
---@param cwd string
---@return pibuf.Skill[]
function M.discover(cwd)
  local manifest = M.consume_manifest()
  if manifest then
    return manifest
  end

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
  for _, dir in ipairs(require("pibuf.config").skills.extra_paths or {}) do
    for _, s in ipairs(M.scan_dir(dir, false)) do
      add(s)
    end
  end
  return skills
end

---Get the cached skills for a buffer's project cwd, discovering if needed.
---@param buf integer
---@return pibuf.Skill[]
function M.get(buf)
  local cwd = Util.get_cwd(buf)
  if state.cwd == cwd and state.skills then
    return state.skills
  end
  state.cwd = cwd
  state.skills = M.discover(cwd)
  return state.skills
end

---Invalidate the cache. Re-discovers for `buf` if given.
---@param buf? integer
function M.refresh(buf)
  state.cwd = nil
  state.skills = nil
  if buf then
    M.get(buf)
  end
end

return M
