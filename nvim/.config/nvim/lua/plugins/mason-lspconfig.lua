return {
  {
    "williamboman/mason-lspconfig.nvim",
     config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "tsserver", "pyright" },
        automatic_installation = true,
      })
    end
  }
}

