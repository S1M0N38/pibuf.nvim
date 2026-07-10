# Changelog

## 1.0.0 (2026-07-10)


### ⚠ BREAKING CHANGES

* setup() no longer accepts options. The skills.extra_paths option is removed; Pi built-in skill sources (user-global, project, config-dir, package) cover the same ground.
* README/vimdoc no longer describe a template workflow.
* every `require("base*")` path is now `require("pibuf*")`. Update any consumer config accordingly.

### Features

* implement `[@file](https://github.com/file)` and /skill completion for pi buffers ([e044b52](https://github.com/S1M0N38/pibuf.nvim/commit/e044b52faa6de6dcc2bbdf6d204fdf2bde4053da))


### Documentation

* replace template documentation with plugin description ([231c28f](https://github.com/S1M0N38/pibuf.nvim/commit/231c28f5e6a5de3c2cec0becd85c3a2aa88b5e59))


### Code Refactoring

* remove config system and helper modules ([43f8d1a](https://github.com/S1M0N38/pibuf.nvim/commit/43f8d1ac36812ed6a18027e72bc635a94c69989d))
* rename template placeholders to pibuf.nvim ([d28f239](https://github.com/S1M0N38/pibuf.nvim/commit/d28f23990c12434c22d5f5f7bb70b0fb59db743c))
