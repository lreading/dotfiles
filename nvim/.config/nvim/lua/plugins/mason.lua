return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "black",
          "rubocop",
          "isort",
          "gopls",
        },
        auto_update = true,
        run_on_start = true,
      })
    end,
  },
}

