return {
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"ts_ls",
					"pyright",
					"html",
					"eslint",
					"intelephense",
					"bashls",
					"jsonls",
					"yamlls",
					"dockerls",
					"rust-analyzer",
				},
				automatic_installation = true,
			})
			require("mason-lspconfig").setup({
				function(server_name)
					if server_name == "tsserver" then
						server_name = "ts_ls"
					end
					local capabilities = require("cmp_nvim_lsp").default_capabilities()
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
					})
				end,
			})
		end,
	},
}
