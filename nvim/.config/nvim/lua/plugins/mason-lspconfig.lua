return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},
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
					"rust_analyzer",
				},
				-- install servers that are configured elsewhere
				automatic_installation = true,
				-- IMPORTANT: let nvim-lspconfig.lua call vim.lsp.enable
				automatic_enable = false,
			})
		end,
	},
}
