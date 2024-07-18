return {
  {
    "williamboman/mason-lspconfig.nvim",
     config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "tsserver", "pyright", "html", "eslint", "intelephense"},
        automatic_installation = true,
      })
    end
  }
}

