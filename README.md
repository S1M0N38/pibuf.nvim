<div align="center">
  <h1>⛶&nbsp;&nbsp;pibuf.nvim&nbsp;&nbsp;⛶ </h1>

  <p align="center">
    <a href="https://github.com/S1M0N38/pibuf.nvim/actions/workflows/ci.yml">
      <img alt="CI badge" src="https://img.shields.io/github/actions/workflow/status/S1M0N38/pibuf.nvim/ci.yml?style=for-the-badge&label=CI"/>
    </a>
    <a href="https://luarocks.org/modules/S1M0N38/pibuf.nvim">
      <img alt="LuaRocks badge" src="https://img.shields.io/luarocks/v/S1M0N38/pibuf.nvim?style=for-the-badge&color=5d2fbf"/>
    </a>
    <a href="https://github.com/S1M0N38/pibuf.nvim/releases">
      <img alt="GitHub badge" src="https://img.shields.io/github/v/release/S1M0N38/pibuf.nvim?style=for-the-badge&label=GitHub"/>
    </a>
  </p>
  <p><em>A focused prompt-editing mode for the Pi coding agent, activated on Ctrl-G.</em></p>
</div>

______________________________________________________________________

## 💡 Motivation

When you press `Ctrl-G` in the [Pi coding agent](https://github.com/earendil-works/pi-coding-agent),
Pi writes your prompt to a temp file and opens it in `$VISUAL`. pibuf.nvim
detects that buffer and augments it with:

- **`@file` completion** — reference project files by relative path.
- **`/skill:<name>` completion** — invoke an installed Pi skill.
- **Syntax highlighting** for `@file` and `/skill:` tokens.
- A **winbar hint** and an **unsaved-changes guard**.

Completion is a [blink.cmp](https://github.com/saghen/blink.cmp) source — pibuf
generates candidates, blink does the fuzzy filtering.

## ⚡ Requirements

- Neovim >= 0.12
- [blink.cmp](https://github.com/saghen/blink.cmp)
- [`fd`](https://github.com/sharkdp/fd) (optional; vim.fs fallback otherwise)
- Pi, with `$VISUAL` pointing at Neovim, e.g.
  `export VISUAL="env NVIM_APPNAME=lazyvim nvim"`

## 📦 Installation

Install using [lazy.nvim](https://github.com/folke/lazy.nvim), and register
pibuf as a blink.cmp source for the `pi` filetype:

```lua
{
  "S1M0N38/pibuf.nvim",
  opts = {},
},
{
  "saghen/blink.cmp",
  opts = {
    sources = {
      per_filetype = { pi = { "pibuf" } },
      providers = {
        pibuf = { name = "Pibuf", module = "pibuf.source" },
      },
    },
  },
},
```

For development, see [CONTRIBUTING.md](CONTRIBUTING.md).

## 🚀 Usage

1. Press `Ctrl-G` in Pi — pibuf sets the buffer filetype to `pi`.
2. Edit the prompt: type `@` for files, `/` for skills.
3. `:wq` / `ZZ` to send the edited prompt; `:cq` to cancel and keep the
   original.

```lua
require("pibuf").setup({
  files = { max_results = 50 },          -- project-wide @file search cap
  skills = { extra_paths = {} },        -- extra skill dirs
  winbar = { enabled = true },          -- send/cancel hint
  guard = { unwritten = true },         -- warn on unsaved close
})
```

Run `:Pibuf refresh` to rebuild the skill cache, and `:checkhealth pibuf` to
verify your setup.

## 🙏 Acknowledgments

Inspired by the `pi-nvim` prototype config. Completion powered by
[blink.cmp](https://github.com/saghen/blink.cmp).
