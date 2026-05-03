return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
		config = function()
			local parsers = { "lua", "javascript", "vue", "rust", "markdown", "markdown_inline" }
			local filetypes = { "lua", "javascript", "vue", "rust", "markdown" }

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

			local treesitter = require("nvim-treesitter")
			treesitter.install(parsers)

			vim.api.nvim_create_autocmd("FileType", {
				pattern = filetypes,
				callback = function()
					vim.treesitter.start()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})

			require("nvim-treesitter-textobjects").setup({
				select = {
					lookahead = true,
				},
				move = {
					set_jumps = true,
				},
			})

			local select = require("nvim-treesitter-textobjects.select")
			vim.keymap.set({ "x", "o" }, "af", function()
				select.select_textobject("@function.outer", "textobjects")
			end, { desc = "Select around function" })
			vim.keymap.set({ "x", "o" }, "if", function()
				select.select_textobject("@function.inner", "textobjects")
			end, { desc = "Select inside function" })
			vim.keymap.set({ "x", "o" }, "ac", function()
				select.select_textobject("@class.outer", "textobjects")
			end, { desc = "Select around class" })
			vim.keymap.set({ "x", "o" }, "ic", function()
				select.select_textobject("@class.inner", "textobjects")
			end, { desc = "Select inside class" })

			local swap = require("nvim-treesitter-textobjects.swap")
			vim.keymap.set("n", "<leader>a", function()
				swap.swap_next("@parameter.inner", "textobjects")
			end, { desc = "Swap parameter with next" })
			vim.keymap.set("n", "<leader>A", function()
				swap.swap_previous("@parameter.inner", "textobjects")
			end, { desc = "Swap parameter with previous" })

			local move = require("nvim-treesitter-textobjects.move")
			vim.keymap.set({ "n", "x", "o" }, "]m", function()
				move.goto_next_start("@function.outer", "textobjects")
			end, { desc = "Go to next function start" })
			vim.keymap.set({ "n", "x", "o" }, "]M", function()
				move.goto_next_end("@function.outer", "textobjects")
			end, { desc = "Go to next function end" })
			vim.keymap.set({ "n", "x", "o" }, "[m", function()
				move.goto_previous_start("@function.outer", "textobjects")
			end, { desc = "Go to previous function start" })
			vim.keymap.set({ "n", "x", "o" }, "[M", function()
				move.goto_previous_end("@function.outer", "textobjects")
			end, { desc = "Go to previous function end" })
		end,
	},
}
