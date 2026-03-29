return {
  {
    "folke/neoconf.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("neoconf").setup({
        local_settings = ".neoconf.json",
        import = {
          vscode = false,
          coc = false,
          nlsp = false,
        },
      })

      require("neoconf.plugins").register({
        name = "neotest",
        on_schema = function(schema)
          schema:import("neotest", require("neotest-project").schema_defaults())
        end,
      })
    end,
  },
}
