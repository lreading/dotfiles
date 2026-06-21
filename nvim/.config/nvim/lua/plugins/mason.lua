return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"black",
					"isort",
					"gopls",
					"prettier",
					"stylua",
				},
				auto_update = true,
				run_on_start = true,
			})
		end,
	},
}
