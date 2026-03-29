return {
	"milanglacier/minuet-ai.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("minuet").setup({
			provider = "openai_fim_compatible",

			n_completions = 1,
			request_timeout = 5,
			throttle = 300,
			debounce = 150,
			context_window = 512,

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
						stream = false,
						optional = {
							max_tokens = 64,
							top_p = 0.9,
							repeat_penalty = 1.05,
							stop = { "\n\n" },
						},
					},
			},
		})
	end,
}
