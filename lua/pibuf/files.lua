---`@file` candidate generation for the file-mention completion.
---
---Two modes (dispatched by `candidates`):
---  * dir-scoped:  `@<dir>/<part>` or `@` alone -> list entries in `<dir>`
---  * project-wide: `@<part>` (no slash) -> fd substring search over the cwd
---
---fd is the primary backend (Pi already requires it; gitignore-aware, fast);
---vim.fs is the fallback, flagged by `:checkhealth pibuf`.
local M = {}

local Util = require("pibuf.util")

-- Dirs skipped in dir-scoped listings (non-hidden junk that isn't always
-- gitignored). Hidden entries (leading `.`) are always skipped.
local SKIP_DIRS = {
  ["node_modules"] = true,
  ["__pycache__"] = true,
  ["dist"] = true,
  ["build"] = true,
  [".next"] = true,
  ["target"] = true,
  [".cache"] = true,
  ["vendor"] = true,
}

-- Excluded from the project-wide fd search for the same reason.
local FD_EXCLUDES = {
  "node_modules",
  "__pycache__",
  "dist",
  "build",
  ".next",
  "target",
  ".cache",
  "vendor",
}

---@class pibuf.FileCand
---@field path string  relpath from the project root
---@field is_dir boolean

---List entries in `dir` (absolute) whose name starts with `prefix`
---(case-insensitive), returning relpaths prefixed with `subdir`.
---@param dir string absolute path to list
---@param prefix string filter prefix (may be empty -> list all, capped)
---@param subdir string relpath prefix relative to project root (no slashes)
---@param cap integer
---@return pibuf.FileCand[]
function M.list_dir(dir, prefix, subdir, cap)
  local results = {}
  if not Util.is_dir(dir) then
    return results
  end
  local plower = prefix:lower()
  for name, type in vim.fs.dir(dir) do
    if #results >= cap then
      break
    end
    if not name:match("^%.") and not SKIP_DIRS[name] then
      if plower == "" or name:sub(1, #plower):lower() == plower then
        results[#results + 1] = {
          path = subdir == "" and name or (subdir .. "/" .. name),
          is_dir = (type == "directory"),
        }
      end
    end
  end
  table.sort(results, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir
    end
    return a.path < b.path
  end)
  return results
end

---Run fd for a project-wide substring search over `root`.
---fd prints absolute paths when given an absolute root, so we convert each
---result back to a relpath with `vim.fs.relpath`.
---@param root string absolute path
---@param query string literal substring (no slash expected)
---@param cap integer
---@return pibuf.FileCand[]
function M.search_fd(root, query, cap)
  local args = { "fd", "-i", "-F", "-p", "--max-results", tostring(cap) }
  for _, ex in ipairs(FD_EXCLUDES) do
    args[#args + 1] = "--exclude"
    args[#args + 1] = ex
  end
  args[#args + 1] = query
  args[#args + 1] = root
  local out = vim.fn.systemlist(args)
  if vim.v.shell_error ~= 0 then
    return {}
  end
  local results = {}
  for _, abs in ipairs(out) do
    if abs ~= "" then
      local rel = vim.fs.relpath(root, abs) or abs
      local stat = vim.uv.fs_stat(abs)
      results[#results + 1] = {
        path = rel,
        is_dir = stat ~= nil and stat.type == "directory" or false,
      }
    end
  end
  return results
end

---vim.fs fallback when fd is absent.
---@param root string
---@param query string
---@param cap integer
---@return pibuf.FileCand[]
function M.search_vimfs(root, query, cap)
  local qlower = query:lower()
  local found = vim.fs.find(function(name, path)
    local rel = vim.fs.relpath(root, vim.fs.joinpath(path, name)) or name
    return rel:lower():find(qlower, 1, true) ~= nil
  end, { limit = cap, path = root })
  local results = {}
  for _, full in ipairs(found) do
    local rel = vim.fs.relpath(root, full)
    if rel then
      local stat = vim.uv.fs_stat(full)
      results[#results + 1] = {
        path = rel,
        is_dir = stat ~= nil and stat.type == "directory" or false,
      }
    end
  end
  return results
end

---Project-wide search (fd with vim.fs fallback).
---@param root string
---@param query string
---@param cap integer
---@return pibuf.FileCand[]
function M.search_project(root, query, cap)
  root = vim.fn.fnamemodify(root, ":p") -- ensure absolute for relpath math
  if Util.has_fd() then
    return M.search_fd(root, query, cap)
  end
  return M.search_vimfs(root, query, cap)
end

---Compute file candidates for a `@<base>` mention.
---@param cwd string project root (snapshotted)
---@param base string text between `@` and cursor (excluding `@`)
---@param cap? integer override max results (defaults to config.files.max_results)
---@return pibuf.FileCand[]
function M.candidates(cwd, base, cap)
  cap = cap or require("pibuf.config").files.max_results
  if base == "" then
    return M.list_dir(cwd, "", "", cap)
  end
  -- dir-scoped when base contains a slash: `@<subdir>/<prefix>`
  -- `.*()/` returns the 1-indexed position of the last `/`.
  local last_slash = base:match(".*()/")
  if last_slash then
    local subdir = base:sub(1, last_slash - 1)
    local prefix = base:sub(last_slash + 1)
    return M.list_dir(vim.fs.joinpath(cwd, subdir), prefix, subdir, cap)
  end
  return M.search_project(cwd, base, cap)
end

return M
