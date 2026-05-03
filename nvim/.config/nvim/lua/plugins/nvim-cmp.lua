return {
	{
		"hrsh7th/cmp-nvim-lsp",
	},
	{
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require("cmp")

			local function feedkeys(keys)
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", true)
			end

			cmp.setup({
				performance = {
					fetching_timeout = 2000,
				},

				window = {
					completion = cmp.config.window.bordered({
						max_height = 12,
					}),
					documentation = cmp.config.window.bordered({
						max_width = 60,
						max_height = 20,
					}),
				},

				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),

					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<C-Enter>"] = cmp.mapping.confirm({ select = true }),

					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
							return
						end

						fallback()
					end, { "i", "s" }),

					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
							return
						end
						fallback()
					end, { "i", "s" }),

					["<C-c>"] = cmp.mapping(function(fallback)
						fallback()
						feedkeys("<C-c>")
					end, { "i", "s" }),
				}),

				formatting = {
					fields = { "kind", "abbr" },
				},

				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
				}, {
					{ name = "buffer" },
				}),
			})
		end,
	},
}
