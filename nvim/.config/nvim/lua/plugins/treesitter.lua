return {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
		build = ":TSUpdate",
		config = function()
			local function first_capture(match, capture_id)
				local nodes = match[capture_id]
				if type(nodes) == "table" then
					return nodes[1]
				end

				return nodes
			end

			local html_script_type_languages = {
				importmap = "json",
				module = "javascript",
				["application/ecmascript"] = "javascript",
				["text/ecmascript"] = "javascript",
			}

			local markdown_language_aliases = {
				ex = "elixir",
				pl = "perl",
				sh = "bash",
				ts = "typescript",
				uxn = "uxntal",
			}

			vim.treesitter.query.add_directive("set-lang-from-info-string!", function(match, _, source, pred, metadata)
				local node = first_capture(match, pred[2])
				if not node then
					return
				end

				local alias = vim.treesitter.get_node_text(node, source):lower()
				metadata["injection.language"] = vim.filetype.match({ filename = "a." .. alias })
					or markdown_language_aliases[alias]
					or alias
			end, { force = true, all = false })

			vim.treesitter.query.add_directive("set-lang-from-mimetype!", function(match, _, source, pred, metadata)
				local node = first_capture(match, pred[2])
				if not node then
					return
				end

				local mimetype = vim.treesitter.get_node_text(node, source)
				local parts = vim.split(mimetype, "/", {})
				metadata["injection.language"] = html_script_type_languages[mimetype] or parts[#parts]
			end, { force = true, all = false })

			vim.treesitter.query.add_directive("downcase!", function(match, _, source, pred, metadata)
				local id = pred[2]
				local node = first_capture(match, id)
				if not node then
					return
				end

				local text = vim.treesitter.get_node_text(node, source, { metadata = metadata[id] }) or ""
				metadata[id] = metadata[id] or {}
				metadata[id].text = string.lower(text)
			end, { force = true, all = false })

			local config = require("nvim-treesitter.configs")
			config.setup({
				ensure_installed = { "lua", "javascript", "vue", "rust", "markdown", "markdown_inline" },
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
				textobjects = {
					select = {
						enable = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
						},
					},
					swap = {
						enable = true,
						swap_next = { ["<leader>a"] = "@parameter.inner" },
						swap_previous = { ["<leader>A"] = "@parameter.inner" },
					},
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = { ["]m"] = "@function.outer" },
						goto_next_end = { ["]M"] = "@function.outer" },
						goto_previous_start = { ["[m"] = "@function.outer" },
						goto_previous_end = { ["[M"] = "@function.outer" },
					},
					lsp_interop = {
						enable = true,
						peek_definition_code = {
							["gd"] = "@function.outer",
							["gD"] = "@class.outer",
						},
					},
				},
			})
		end,
	},
}
