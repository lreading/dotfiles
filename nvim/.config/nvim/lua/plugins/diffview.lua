return {
	{
		"sindrets/diffview.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewFileHistory",
			"DiffviewToggleFiles",
			"DiffviewFocusFiles",
			"DiffviewRefresh",
		},
		keys = {
			{
				"<leader>dv",
				function()
					local ok, lib = pcall(require, "diffview.lib")
					if ok and next(lib.views) ~= nil then
						vim.cmd("DiffviewClose")
					else
						vim.cmd("DiffviewOpen")
					end
				end,
				desc = "Toggle Diffview",
			},
			{
				"<leader>dV",
				"<cmd>DiffviewFileHistory %<cr>",
				desc = "Current File History",
			},
		},
		opts = function()
			local actions = require("diffview.actions")

			return {
				view = {
					merge_tool = {
						layout = "diff3_mixed",
						disable_diagnostics = true,
					},
				},
				file_panel = {
					listing_style = "tree",
					win_config = {
						position = "left",
						width = 35,
					},
				},
				keymaps = {
					disable_defaults = false,
					view = {
						{
							"n",
							"<leader>ko",
							actions.conflict_choose("ours"),
							{ desc = "Keep OURS for the current conflict" },
						},
						{
							"n",
							"<leader>kt",
							actions.conflict_choose("theirs"),
							{ desc = "Keep THEIRS for the current conflict" },
						},
						{
							"n",
							"<leader>kb",
							actions.conflict_choose("base"),
							{ desc = "Keep BASE for the current conflict" },
						},
						{
							"n",
							"<leader>ka",
							actions.conflict_choose("all"),
							{ desc = "Keep ALL versions for the current conflict" },
						},
						{
							"n",
							"<leader>kn",
							actions.conflict_choose("none"),
							{ desc = "Keep NONE for the current conflict" },
						},
						{
							"n",
							"<leader>kO",
							actions.conflict_choose_all("ours"),
							{ desc = "Keep OURS for the whole file" },
						},
						{
							"n",
							"<leader>kT",
							actions.conflict_choose_all("theirs"),
							{ desc = "Keep THEIRS for the whole file" },
						},
						{
							"n",
							"<leader>kB",
							actions.conflict_choose_all("base"),
							{ desc = "Keep BASE for the whole file" },
						},
						{
							"n",
							"<leader>kA",
							actions.conflict_choose_all("all"),
							{ desc = "Keep ALL versions for the whole file" },
						},
						{
							"n",
							"<leader>kN",
							actions.conflict_choose_all("none"),
							{ desc = "Keep NONE for the whole file" },
						},
					},
					file_panel = {
						{
							"n",
							"<leader>kO",
							actions.conflict_choose_all("ours"),
							{ desc = "Keep OURS for the whole file" },
						},
						{
							"n",
							"<leader>kT",
							actions.conflict_choose_all("theirs"),
							{ desc = "Keep THEIRS for the whole file" },
						},
						{
							"n",
							"<leader>kB",
							actions.conflict_choose_all("base"),
							{ desc = "Keep BASE for the whole file" },
						},
						{
							"n",
							"<leader>kA",
							actions.conflict_choose_all("all"),
							{ desc = "Keep ALL versions for the whole file" },
						},
						{
							"n",
							"<leader>kN",
							actions.conflict_choose_all("none"),
							{ desc = "Keep NONE for the whole file" },
						},
					},
				},
			}
		end,
	},
}
