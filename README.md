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
  <p><em>Picker-backed prompt editing for the Pi coding agent, activated on Ctrl-G.</em></p>
</div>

______________________________________________________________________

## 💡 Motivation

When you press `Ctrl-G` in the [Pi coding agent](https://github.com/earendil-works/pi-coding-agent),
Pi writes your prompt to a temp file and opens it in `$VISUAL`. pibuf.nvim
detects that buffer (filetype `pi`) and adds two buffer-local pickers:

- **`<C-f>`** — pick a project file and insert an `@<path>` mention.
- **`<C-s>`** — pick an installed Pi skill and insert a `/skill:<name>` reference.

Pickers are powered by [snacks.nvim](https://github.com/folke/snacks.nvim).

## ⚡ Requirements

- Neovim >= 0.12
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- Pi, with `$VISUAL` pointing at Neovim, e.g.
  `export VISUAL="env NVIM_APPNAME=lazyvim nvim"`

## 📦 Installation

Install using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "S1M0N38/pibuf.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {},
}
```

`opts = {}` lets lazy.nvim auto-call `setup()`, which registers the `pi`
filetype detection and the picker keymaps. No manual `setup()` call needed.

For development, see [CONTRIBUTING.md](CONTRIBUTING.md).

## 🚀 Usage

1. Press `Ctrl-G` in Pi — pibuf sets the buffer filetype to `pi`.
2. Edit the prompt:
   - `<C-f>` opens a file picker (project root); confirm to insert `@<path>`.
   - `<C-s>` opens a skills picker; confirm to insert `/skill:<name>`.
3. `:wq` / `ZZ` to send the edited prompt; `:cq` to cancel and keep the
   original.

Run `:checkhealth pibuf` to verify your setup.
