# pibuf.nvim

A Neovim plugin that augments the buffer Pi's coding agent opens via Ctrl-G with
completion and editing support for writing Pi prompts.

## Language

**Pi buffer**:
The throwaway buffer Neovim opens when Pi's external-editor command launches it,
backed by a temp file Pi reads back on quit.
_Avoid_: prompt buffer, scratch buffer, editor buffer

**file mention**:
The `@<path>` token in a Pi buffer that references a project file.
_Avoid_: file ref, at-mention

**skill**:
A reusable capability Pi loads from a `SKILL.md` resource (user-global, project,
config-dir, or package sources).

**skill reference**:
The `/skill:<name>` token in a Pi buffer that invokes a skill.
_Avoid_: skill command, skill mention
