return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {},
	},
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

			local ok, lspconfig_util = pcall(require, "lspconfig.util")
			if ok then
				lspconfig_util.available_servers = function()
					return vim.tbl_keys(vim.lsp.config._configs or {})
				end
			end

			require("neoconf.plugins").register({
				name = "neotest",
				on_schema = function(schema)
					schema:import("neotest", require("neotest-project").schema_defaults())
				end,
			})
		end,
	},
}
