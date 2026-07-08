" pibuf.nvim syntax for the `pi` filetype.
" Sourced automatically when Neovim sets filetype=pi (requires `:filetype syntax on`).

if exists("b:current_syntax")
  finish
endif

" @file mention: `@` + non-whitespace.
syntax match pibufFileRef /@\S\+/

" /skill:<name> reference: `/skill:` at a token boundary + the skill name.
syntax match pibufSkill /\%(^\|\s\)\@<=\/skill:[[:alnum:]_-]*/

highlight def link pibufFileRef Identifier
highlight def link pibufSkill Function

let b:current_syntax = "pi"
