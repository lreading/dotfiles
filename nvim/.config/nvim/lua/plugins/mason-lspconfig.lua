return {
  {
    "williamboman/mason-lspconfig.nvim",
     config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "tsserver", "pyright", "html", "eslint", "intelephense", "bashls", "jsonls", "yamlls", "dockerls" },
        automatic_installation = true,
      })
    end
  }
}

