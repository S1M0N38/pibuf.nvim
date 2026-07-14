# Changelog

## [1.1.0](https://github.com/S1M0N38/pibuf.nvim/compare/v1.0.0...v1.1.0) (2026-07-14)


### Features

* **pickers:** support multiple fuzzy-finder backends ([ff0e2fa](https://github.com/S1M0N38/pibuf.nvim/commit/ff0e2fa23f577f50ab5f0ec29494fe583ea14ef9)), closes [#3](https://github.com/S1M0N38/pibuf.nvim/issues/3)
* **pickers:** wrap and verticalize skills preview ([e37f3fd](https://github.com/S1M0N38/pibuf.nvim/commit/e37f3fd8957f37573aa7fafb7be4478bab31f1ff))


### Bug Fixes

* **config:** make unknown picker a soft error ([052e15f](https://github.com/S1M0N38/pibuf.nvim/commit/052e15fb9a5a5bf14affbac162a477aabbaa96ce))
* **pickers:** harden async notification and buffer insert ([2251d09](https://github.com/S1M0N38/pibuf.nvim/commit/2251d090eb0451331a32597f241be2b3d77b4f8e))
* **pickers:** land cursor after trailing space on mention insert ([3c1ad5e](https://github.com/S1M0N38/pibuf.nvim/commit/3c1ad5ec58dda58ce119ab3f1caa05cd34600850))
* **pickers:** override mini.pick choose to prevent side effects ([35d7dfa](https://github.com/S1M0N38/pibuf.nvim/commit/35d7dfabc981d79f9ac96ced1957fe7a3820f245))
* **pickers:** strip fzf-lua file icon from inserted mention ([66bd12a](https://github.com/S1M0N38/pibuf.nvim/commit/66bd12a7313135cb75f42513dff2d1b299b40244))

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
