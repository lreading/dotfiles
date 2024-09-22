return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local config = require("lspconfig")

      config.lua_ls.setup({
        capabilities = capabilities,
      })
      config.html.setup({
        capabilities = capabilities,
      })
      config.ts_ls.setup({
        capabilities = capabilities,
        on_attach = function(client)
          client.server_capabilities.document_formatting = false
        end,
      })
      config.pyright.setup({
        capabilities = capabilities,
      })
      config.eslint.setup({
        capabilities = capabilities,
        settings = {
          packageManager = "pnpm",
        },
      })
      config.intelephense.setup({
        capabilities = capabilities,
      })
      config.bashls.setup({
        capabilities = capabilities,
      })
      config.jsonls.setup({
        capabilities = capabilities,
      })
      config.yamlls.setup({
        capabilities = capabilities,
      })
      config.dockerls.setup({
        capabilities = capabilities,
      })
      config.volar.setup({
        capabilities = capabilities,
      })

      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.rename, {})
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "<C-gk>", vim.lsp.buf.signature_help, {})
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
    end,
  },
}
