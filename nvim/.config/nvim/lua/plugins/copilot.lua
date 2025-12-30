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
				-- IMPORTANT: disable built-in accept key
				keymap = {
					accept = false,
					accept_word = false,
					accept_line = false,
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
		},
		config = function(_, opts)
			require("copilot").setup(opts)

			-- "Super Tab": accept Copilot suggestion if visible, otherwise send a normal <Tab>
			_G.copilot_super_tab = function()
				local ok, suggestion = pcall(require, "copilot.suggestion")
				if ok and suggestion.is_visible() then
					suggestion.accept()
					return ""
				end

				-- fallback: behave like a normal Tab
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
