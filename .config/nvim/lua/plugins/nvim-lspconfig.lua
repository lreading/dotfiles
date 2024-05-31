return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local config = require("lspconfig")

      config.lua_ls.setup({
        capabilities = capabilities
      })
      config.html.setup({
        capabilities = capabilities
      })
      config.tsserver.setup({
        capabilities = capabilities
      })
      config.pyright.setup({
        capabilities = capabilities
      })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "<C-gk>", vim.lsp.buf.signature_help, {})
      vim.keymap.set({"n", "v"}, "<leader>ca", vim.lsp.buf.code_action, {})
      vim.keymap.set("n", "<leader>f", function()
        vim.lsp.buf.format { async = true }
      end, {})
    end
  }
}

