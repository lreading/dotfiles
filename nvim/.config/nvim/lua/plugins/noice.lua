return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
	config = function()
		require("notify").setup({
			background_colour = "#000000",
			merge_duplicates = true,
			top_down = false,
		})
		require("noice").setup({
			routes = {
				{
					filter = {
						event = "msg_show",
						find = "Type  :qa!  and press <Enter> to abandon all changes and exit Nvim",
					},
					opts = { skip = true },
				},
				{
					view = "notify",
					filter = {
						event = "msg_show",
						kind = { "", "echo", "echomsg", "lua_print", "list_cmd" },
						max_height = 19,
					},
					opts = {
						merge = false,
						replace = false,
						title = "Messages",
					},
				},
			},
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
				},
			},
			presets = {
				bottom_search = true, -- use a classic bottom cmdline for search
				command_palette = true, -- position the cmdline and popupmenu together
				long_message_to_split = true, -- long messages will be sent to a split
				inc_rename = false, -- enables an input dialog for inc-rename.nvim
				lsp_doc_border = false, -- add a border to hover docs and signature help
			},
			views = {
				cmdline_popup = {
					position = {
						row = "50%", -- Centered vertically
						col = "50%", -- Centered horizontally
					},
					size = {
						width = 60,
						height = "auto",
					},
					border = {
						style = "rounded",
						padding = { 1, 2 },
					},
					win_options = {
						winblend = 10, -- Transparency effect
						winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
					},
				},
				popupmenu = {
					position = {
						row = "50%", -- Centered vertically
						col = "50%", -- Centered horizontally
					},
					size = {
						width = 60,
						height = 10,
					},
					border = {
						style = "rounded",
						padding = { 1, 2 },
					},
					win_options = {
						winblend = 10,
					},
				},
			},
		})

		-- Let nvim-notify handle repeated command messages instead of Noice dropping them as duplicates.
		local state = require("noice.ui.state")
		local original_skip = state.skip
		state.skip = function(event, kind, ...)
			if event == "msg_show" and vim.tbl_contains({ "", "echo", "echomsg", "lua_print", "list_cmd" }, kind) then
				state.set(event, kind, ...)
				return false
			end

			return original_skip(event, kind, ...)
		end
	end,
}
