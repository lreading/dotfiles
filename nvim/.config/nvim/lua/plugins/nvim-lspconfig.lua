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
			config.ts_ls.setup({
				capabilities = capabilities,
				on_attach = function(client)
					client.server_capabilities.document_formatting = false
				end,
			})
			config.pyright.setup({
				capabilities = capabilities,
			})
			config.eslint.setup({
				capabilities = capabilities,
				settings = {
					packageManager = "pnpm",
				},
			})
			config.intelephense.setup({
				capabilities = capabilities,
			})
			config.bashls.setup({
				capabilities = capabilities,
			})
			config.jsonls.setup({
				capabilities = capabilities,
			})
			config.yamlls.setup({
				capabilities = capabilities,
			})
			config.dockerls.setup({
				capabilities = capabilities,
			})
			config.volar.setup({
				capabilities = capabilities,
				filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue", "json" },
			})

			config.solargraph.setup({
				cmd = { "solargraph", "stdio" },
				filetypes = { "ruby" },
				root_dir = require("lspconfig.util").root_pattern("Gemfile", ".git"),
				settings = {
					solargraph = {
						diagnostics = true,
					},
				},
			})

			config.gopls.setup({
				cmd = { "gopls" },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				root_dir = config.util.root_pattern("go.work", "go.mod", ".git"),
				settings = {
					gopls = {
						usePlaceholders = true, -- Enables placeholders in function signatures
						completeUnimported = true, -- Auto-imports packages
						staticcheck = true, -- Enable static analysis
					},
				},
			})

			config.rust_analyzer.setup({
				capabilities = capabilities,
			})
			vim.keymap.set("n", "<leader>gr", vim.lsp.buf.rename, {})
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "<C-gk>", vim.lsp.buf.signature_help, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})

			vim.lsp.handlers["textDocument/hover"] = function(_, result, ctx, config)
				if not (result and result.contents) then
					return
				end

				local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
				if vim.tbl_isempty(markdown_lines) then
					return
				end

				config = config or {}
				config.border = "rounded"
				config.width = 80
				config.height = math.min(#markdown_lines, 20) -- Dynamically adjust height
				vim.lsp.util.open_floating_preview(markdown_lines, "markdown", config)
			end
		end,
	},
}
