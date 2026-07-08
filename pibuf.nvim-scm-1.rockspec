---@diagnostic disable: lowercase-global

local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
version = _MODREV .. _SPECREV

local user = "S1M0N38"
package = "pibuf.nvim"

description = {
	summary = "A focused prompt-editing mode for the Pi coding agent, activated on Ctrl-G.",
	detailed = [[
pibuf.nvim auto-activates when the Pi coding agent opens Neovim via Ctrl-G
and augments the prompt buffer with project-scoped @file completion and
/skill:* completion, plus syntax highlighting for mentions and a
distraction-free editing environment.
  ]],
	labels = { "neovim", "plugin", "pi", "prompt", "completion" },
	homepage = "https://github.com/" .. user .. "/" .. package,
	license = "MIT",
}

dependencies = {
	"lua >= 5.1",
}

source = {
	url = "git://github.com/" .. user .. "/" .. package,
}

build = {
	type = "builtin",
}
