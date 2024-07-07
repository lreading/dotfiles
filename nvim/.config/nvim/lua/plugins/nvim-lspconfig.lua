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
			config.tsserver.setup({
				capabilities = capabilities,
			})
			config.pyright.setup({
				capabilities = capabilities,
			})
			config.eslint.setup({
				capabilities = capabilities,
				settings = {
					packageManager = "pnpm",
				},
				on_attach = function(client)
					vim.api.nvim_create_autocmd("BufWritePre", {
						pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.vue" },
						callback = function()
              
              vim.lsp.buf.execute_command({
                command = "eslint.executeAutofix",
                arguments = { vim.uri_from_bufnr(0) },
              })
							-- client.request("eslint/eslintAutofix", {
							--	textDocument = vim.lsp.util.make_text_document_params(),
							-- })
						end,
					})
				end,
			})
			vim.keymap.set("n", "<leader>gr", vim.lsp.buf.rename, {})
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "<C-gk>", vim.lsp.buf.signature_help, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
			vim.keymap.set("n", "<leader>f", function()
				vim.lsp.buf.format({ async = true })
			end, {})
		end,
	},
}
