return {
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- No extra config needed, use the defaults
			local simple_servers = {
				"lua_ls",
				"html",
				"pyright",
				"intelephense",
				"bashls",
				"jsonls",
				"yamlls",
				"dockerls",
			}

			for _, name in ipairs(simple_servers) do
				vim.lsp.config(name, {
					capabilities = capabilities,
				})
				vim.lsp.enable(name)
			end

			local vue_language_server_path =
				vim.fn.expand("~/.local/share/pnpm/global/5/node_modules/@vue/language-server")

			local tsserver_filetypes = {
				"typescript",
				"javascript",
				"javascriptreact",
				"typescriptreact",
				"vue",
			}

			local vue_plugin = {
				name = "@vue/typescript-plugin",
				location = vue_language_server_path,
				languages = { "vue" },
				configNamespace = "typescript",
			}

			local ts_ls_config = {
				capabilities = capabilities,
				init_options = {
					plugins = {
						vue_plugin,
					},
				},
				filetypes = tsserver_filetypes,
				on_attach = function(client, _)
					-- Use null-ls / prettier / etc instead of tsserver formatting
					client.server_capabilities.documentFormattingProvider = false
				end,
			}

			vim.lsp.config("ts_ls", ts_ls_config)
			vim.lsp.enable("ts_ls")

			-- vue_ls: Vue language server (Volar), supports Vue 2 + Vue 3
			vim.lsp.config("vue_ls", {
				capabilities = capabilities,
			})
			vim.lsp.enable("vue_ls")

			vim.lsp.config("eslint", {
				capabilities = capabilities,
				settings = {
					packageManager = "pnpm",
				},
			})
			vim.lsp.enable("eslint")

			vim.lsp.config("solargraph", {
				capabilities = capabilities,
				cmd = { "solargraph", "stdio" },
				filetypes = { "ruby" },
				root_markers = { "Gemfile", ".git" },
				settings = {
					solargraph = {
						diagnostics = true,
					},
				},
			})
			vim.lsp.enable("solargraph")

			vim.lsp.config("gopls", {
				capabilities = capabilities,
				cmd = { "gopls" },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				root_markers = { "go.work", "go.mod", ".git" },
				settings = {
					gopls = {
						usePlaceholders = true,
						completeUnimported = true,
						staticcheck = true,
					},
				},
			})
			vim.lsp.enable("gopls")

			vim.lsp.config("rust_analyzer", {
				capabilities = capabilities,
				settings = {
					["rust-analyzer"] = {
						cargo = {
							allTargets = false,
						},
					},
				},
			})
			vim.lsp.enable("rust_analyzer")

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
				config.height = math.min(#markdown_lines, 20)

				vim.lsp.util.open_floating_preview(markdown_lines, "markdown", config)
			end
		end,
	},
}
