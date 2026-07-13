---@diagnostic disable: lowercase-global

local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
version = _MODREV .. _SPECREV

local user = "S1M0N38"
package = "pibuf.nvim"

description = {
	summary = "Picker-backed prompt editing for the Pi coding agent, activated on Ctrl-G.",
	detailed = [[
pibuf.nvim auto-activates when the Pi coding agent opens Neovim via Ctrl-G
and adds two buffer-local pickers to the prompt buffer: <C-f> inserts an
@<path> file mention, and <C-s> inserts a /skill:<name> reference built from
a scan of Pi's skill sources. The fuzzy-finder backend is chosen with the
`picker` option: snacks.nvim (default), telescope.nvim, fzf-lua, or mini.pick.
  ]],
	labels = { "neovim", "plugin", "pi", "prompt", "picker" },
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
