---@meta _
--- Definition file for LuaLS type information. Not loaded at runtime.
--- See: https://luals.github.io/wiki/definition-files/
---
--- Data classes (pibuf.Config and its sub-options, pibuf.Skill,
--- pibuf.FileCand, pibuf.Context) are annotated inline in their runtime
--- modules. This file documents only the module-table surfaces.

-- lua/pibuf/init.lua -----------------------------------------------------------

---@class pibuf.Plugin
---@field did_setup boolean whether setup() has been called
---@field setup fun(opts?: pibuf.Config) setup the plugin with user options
---@field refresh fun() refresh the skill cache for the current buffer

-- lua/pibuf/config.lua ---------------------------------------------------------
-- `pibuf.Config` is the config MODULE table: it exposes the user options
-- (files/skills/winbar/guard, via a metatable over the merged options) AND
-- the module surface (augroup, setup). Data fields are declared in config.lua.

---@class pibuf.Config  (module surface; data fields declared in config.lua)
---@field augroup integer augroup created at module load
---@field setup fun(opts?: pibuf.Config) setup the plugin configuration

-- lua/pibuf/source.lua ---------------------------------------------------------

---@class pibuf.Source
---@field opts table

-- lua/pibuf/util.lua -----------------------------------------------------------

---@class pibuf.Util
---@field notify fun(msg: string|table, level?: integer) send notification with plugin title
---@field info fun(msg: string) send info notification
---@field warn fun(msg: string) send warning notification
---@field error fun(msg: string) send error notification
---@field read_file fun(path: string): string? read a file synchronously
---@field is_dir fun(path: string): boolean
---@field has_fd fun(): boolean
---@field snapshot_cwd fun(buf: integer) snapshot project cwd into a buffer-local var
---@field get_cwd fun(buf: integer): string get the snapshotted cwd (fallback: current cwd)

-- lua/pibuf/health.lua ---------------------------------------------------------

---@class pibuf.Health
---@field check fun() perform health check for the plugin
