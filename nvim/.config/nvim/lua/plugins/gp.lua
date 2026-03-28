return {
	"robitx/gp.nvim",
	config = function()
		require("gp").setup({
			providers = {
				ollama = {
					endpoint = "http://james.leoathome.com:11434/api/chat",
				},
        openai = {
          disable = true,
        },
			},

			agents = {
				{
					provider = "ollama",
					name = "localdev-chat-medium",
					chat = true,
					command = false,
					model = {
						model = "localdev-chat-medium",
						options = { temperature = 0 },
					},
					system_prompt = "You are a senior software engineer. Respond directly and concisely.",
				},
				{
					provider = "ollama",
					name = "localdev-chat-high",
					chat = true,
					command = false,
					model = {
						model = "localdev-chat-high",
						options = { temperature = 0 },
					},
					system_prompt = "You are a senior software engineer. Respond directly and concisely.",
				},
				{
					provider = "ollama",
					name = "localdev-completion",
					chat = false,
					command = true,
					model = {
						model = "localdev-completion",
						options = { temperature = 0 },
					},
					system_prompt = require("gp.defaults").code_system_prompt,
				},
			},

			default_chat_agent = "localdev-chat-medium",
			default_command_agent = "localdev-completion",
		})
	end,
}
