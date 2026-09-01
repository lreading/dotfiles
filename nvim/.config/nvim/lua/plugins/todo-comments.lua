return {
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			keywords = {
				LEO = { icon = " ", color = "error" },
			},
			highlight = {
				comments_only = false,
				pattern = ".*<(KEYWORDS)\\s*[-:]",
			},
			search = {
				pattern = "\\b(KEYWORDS)\\s*[-:]",
			},
		},
		config = function(_, opts)
			local comments = require("todo-comments")

			vim.keymap.set(
				"n",
				"<leader>ft",
				":TodoTelescope<CR>",
				{ noremap = true, silent = true, desc = "Search todo comments" }
			)

			-- vim.keymap.set("n", "<leader>tn", function()
			--   comments.jump_next()
			-- end, { desc = "Next todo comment" })

			-- vim.keymap.set("n", "<leader>tp", function()
			--   comments.jump_prev()
			-- end, { desc = "Previous todo comment" })

			comments.setup(opts)
		end,
	},
}
