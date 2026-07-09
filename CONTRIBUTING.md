# Contributing to pibuf.nvim

Thank you for your interest in contributing to pibuf.nvim!

## Getting Started

1. **Read the documentation**: Start with the [README](README.md) and comprehensive [help documentation](doc/pibuf.txt)
2. **Set up your environment**: Clone the repo and install the dev dependencies (see below)
3. **Test your setup**: Run `make check` to verify everything works

## Development Setup

### Prerequisites

| Tool | Version | Required for | Install |
|------|---------|--------------|---------|
| [Neovim](https://github.com/neovim/neovim) | ≥ 0.12.2 | tests, dev | [releases](https://github.com/neovim/neovim/releases) |
| [StyLua](https://github.com/JohnnyMorganz/StyLua) | 2.4.1 | lint, format | [releases](https://github.com/JohnnyMorganz/StyLua/releases) |
| [lua-language-server](https://github.com/LuaLS/lua-language-server) | latest | type annotations in editor | [releases](https://github.com/LuaLS/lua-language-server/releases) |

### Clone and verify

```bash
git clone https://github.com/S1M0N38/pibuf.nvim.git
cd pibuf.nvim
make check
```

Tests auto-install their dependencies ([mini.test](https://github.com/echasnovski/mini.test) + [luassert](https://github.com/lunarmodules/luassert)) via [lazy.minit](https://github.com/folke/lazy.nvim) on first run. No manual setup required.

## Make Targets

| Target | Description |
|--------|-------------|
| `make test` | Run all tests |
| `make test-one MODULE=pibuf` | Run a single test file (`tests/pibuf_spec.lua`) |
| `make lint` | Check formatting with StyLua (`--check`) |
| `make format` | Auto-format Lua files with StyLua |
| `make typecheck` | Type-check Lua annotations with lua-language-server |
| `make check` | Run lint + typecheck + test |
| `make dev` | Launch Neovim with repro config for manual testing |
| `make clean` | Remove `.repro` and `.tests` working directories |

## Writing Tests

Tests use [mini.test](https://github.com/echasnovski/mini.test) managed by [lazy.minit](https://github.com/folke/lazy.nvim). Write tests in busted-style `describe`/`it` with `luassert` assertions.

### Test structure

```
tests/
├── minit.lua          # Bootstrap entry point (lazy.minit)
├── pibuf_spec.lua     # setup + filetype/keymap tests
├── skills_spec.lua    # skill discovery + frontmatter parsing tests
└── health_spec.lua    # health check tests
```

### Example test

```lua
---@module 'luassert'

local pibuf = require("pibuf")

describe("setup", function()
  it("is idempotent (autocmds don't stack)", function()
    pibuf.setup()
    local before = #vim.api.nvim_get_autocmds({ group = "pibuf" })
    pibuf.setup()
    local after = #vim.api.nvim_get_autocmds({ group = "pibuf" })
    assert.are.equal(before, after)
  end)
end)
```

### Running tests

```bash
make test                          # All tests
make test-one MODULE=pibuf          # Only tests/pibuf_spec.lua
nvim -l tests/minit.lua --minitest tests/pibuf_spec.lua  # Explicit file
```

## GitHub Workflow

### Fork and Clone

1. Fork this repository on GitHub
2. Clone your fork locally:

```bash
git clone https://github.com/your-username/pibuf.nvim.git
cd pibuf.nvim
```

### Create a Branch

```bash
git checkout -b feature/add-awesome-feature
# or
git checkout -b fix/specific-bug-description
```

### Make Your Changes

1. **Write tests**: Add or update tests in the `tests/` directory
2. **Update documentation**: Update `doc/pibuf.txt` and README if needed
3. **Follow coding standards**: Run `make format` before committing

### Commit and Push

Use [conventional commits](https://www.conventionalcommits.org/) for automatic versioning:

```bash
git add .
git commit -m "feat: add awesome new feature"
git push origin feature/add-awesome-feature
```

**Commit types:**
- `feat:` — New features (minor version bump)
- `fix:` — Bug fixes (patch version bump)
- `docs:` — Documentation changes
- `test:` — Adding or updating tests
- `refactor:` — Code refactoring without behavior changes

### Submit a Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Provide a clear title and description
4. Reference any related issues

## CI

Three GitHub Actions workflows run automatically:

| Workflow | Trigger | Jobs |
|----------|---------|------|
| `ci.yml` | Push/PR to `main` | StyLua lint, lua-language-server typecheck, tests (stable + nightly) |
| `release-github.yml` | Push to `main` | release-please (changelog + GitHub release) |
| `release-luarocks.yml` | Push tag `v*.*.*` | LuaRocks publish |

## Bug Reports

When reporting bugs, please:

1. **Use the reproduction environment**: Test with `repro/repro.lua` (`make dev`)
2. **Fill out the issue template**: Provide all requested information
3. **Include steps to reproduce**: Clear, step-by-step instructions

## Development Notes

- **Scope**: pibuf is deliberately small — two pickers for the `pi` prompt buffer. Keep changes focused on that.
- **Keep it simple**: Avoid adding complex dependencies or patterns
- **Document everything**: Both LuaCATS annotations and `doc/pibuf.txt`

Thank you for helping make pibuf.nvim better! 🚀
