return {
	"milanglacier/minuet-ai.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("minuet").setup({
			provider = "openai_fim_compatible",

			n_completions = 1,
			request_timeout = 3,
			throttle = 300,
			debounce = 150,
			context_window = 768,

			-- disable cmp integration (prevents duplicates)
			cmp = {
				enable = false,
			},

			virtualtext = {
				enable = true,

				auto_trigger_ft = { "*" },

				keymap = {
					accept = "<M-CR>",
					accept_line = "<M-S-CR>",
					prev = "<M-[>",
					next = "<M-]>",
					dismiss = "<M-e>",
				},
			},

			provider_options = {
				openai_fim_compatible = {
					api_key = "TERM",
					name = "Ollama",
					end_point = "http://james.leoathome.com:11434/v1/completions",
					model = "localdev-completion",
					stream = true,
					optional = {
						max_tokens = 256,
						top_p = 0.9,
						stop = { "\n\n" },
					},
				},
			},
		})
	end,
}
