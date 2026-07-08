-- pibuf.nvim user commands. The require() is inside the callback so the main
-- module loads only when a command is actually invoked.

local subcommands = {
  refresh = {
    impl = function()
      require("pibuf").refresh()
    end,
    desc = "Refresh the pibuf skill cache",
  },
}

local sub_keys = vim.tbl_keys(subcommands)

vim.api.nvim_create_user_command("Pibuf", function(opts)
  local sub = subcommands[opts.fargs[1]]
  if not sub then
    return vim.notify(
      "Pibuf: unknown subcommand " .. tostring(opts.fargs[1]),
      vim.log.levels.ERROR,
      { title = "pibuf.nvim" }
    )
  end
  sub.impl()
end, {
  nargs = "?",
  desc = "pibuf.nvim",
  complete = function(arg_lead)
    return vim
      .iter(sub_keys)
      :filter(function(k)
        return k:find(arg_lead, 1, true) ~= nil
      end)
      :totable()
  end,
})
