return {
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			local function unsaved_buffers_indicator()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_get_option(buf, "modified") then
						return "⚠️ Unsaved Buffers!"
					end
				end
				return ""
			end

			local function filename_component()
				if vim.bo.filetype == "terminal-manager" then
					return "Terminal Manager"
				end

				if vim.bo.filetype == "trouble" then
					return "Trouble"
				end

				local filename = require("lualine.components.filename"):new({
					path = 1,
					symbols = { modified = "[+]", readonly = "[-]" },
				})

				return filename:get_status()
			end

			require("lualine").setup({
				options = {
					theme = "dracula",
				},
				sections = {
					lualine_c = {
						{ filename_component },
						{ unsaved_buffers_indicator },
					},
				},
				inactive_sections = {
					lualine_c = {
						{ filename_component },
					},
				},
			})
		end,
	},
}
