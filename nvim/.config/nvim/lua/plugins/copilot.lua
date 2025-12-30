return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {
			panel = {
				enabled = false,
			},
			suggestion = {
				enabled = true,
				auto_trigger = true,
				debounce = 75,
				-- IMPORTANT: we handle the accept key ourselves via Super Tab
				keymap = {
					accept = false,
					accept_word = false,
					accept_line = false,
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
			-- Turn down noisy "copilot is not enabled" warnings, if they still happen?
			logger = {
				-- still log to file if you ever want to debug
				-- file_log_level = vim.log.levels.OFF,
				-- print_log_level = vim.log.levels.ERROR,
				trace_lsp = "off",
				trace_lsp_progress = false,
				log_lsp_messages = false,
			},
		},
		config = function(_, opts)
			require("copilot").setup(opts)

			-- Super Tab: accept suggestion if visible, otherwise behave like normal <Tab>
			_G.copilot_super_tab = function()
				local ok, suggestion = pcall(require, "copilot.suggestion")
				if ok and suggestion.is_visible() then
					suggestion.accept()
					return ""
				end

				-- fallback: normal Tab
				return vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
			end

			vim.keymap.set("i", "<Tab>", "v:lua.copilot_super_tab()", {
				expr = true,
				noremap = true,
				silent = true,
				desc = "Copilot Super Tab",
			})

			-- Hide Copilot suggestions when leaving insert / changing mode
			vim.api.nvim_create_autocmd({ "InsertLeave", "ModeChanged" }, {
				callback = function()
					local ok, suggestion = pcall(require, "copilot.suggestion")
					if ok then
						suggestion.dismiss()
					end
				end,
			})
		end,
	},
}
