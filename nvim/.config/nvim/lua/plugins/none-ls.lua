return {
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvimtools/none-ls-extras.nvim",
    },
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        sources = {
          null_ls.builtins.completion.spell.with({
            command = "aspell",
          }),
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.diagnostics.rubocop,
          null_ls.builtins.formatting.rubocop,
          null_ls.builtins.formatting.prettier.with({
            extra_args = {
              "--single-quote",
              "--semi",
              "--print-width=120",
              "--trailing-comma=none",
              "--tab-width=2",
              "--use-tabs=false",
              "--jsx-single-quote",
            },
          }),
          null_ls.builtins.formatting.black,
          null_ls.builtins.formatting.isort,
        },
      })
      vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, {})
    end,
  },
}
