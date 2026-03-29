return {
  {
    "akinsho/toggleterm.nvim",
    config = function()
      local toggleterm = require("toggleterm")
      local Terminal = require("toggleterm.terminal").Terminal
      local terminals = require("toggleterm.terminal")
      local ollama_api_base = vim.env.OLLAMA_API_BASE or "http://james.leoathome.com:11434"
      local aider_model = vim.env.AIDER_MODEL or "ollama_chat/qwen2.5-coder:14b"

      toggleterm.setup({
        open_mapping = [[<C-t>]],
        direction = "float",
        size = 50,
      })

      local aider_cmd = table.concat({
        "env",
        "OLLAMA_API_BASE=" .. ollama_api_base,
        "aider",
        "--model",
        aider_model,
      }, " ")

      local aider = Terminal:new({
        cmd = aider_cmd,
        dir = "git_dir",
        direction = "float",
        hidden = true,
        close_on_exit = false,
        float_opts = {
          border = "curved",
          width = function()
            return math.floor(vim.o.columns * 0.95)
          end,
          height = function()
            return math.floor(vim.o.lines * 0.9)
          end,
        },
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.keymap.set("t", "<C-y>", function()
            term:toggle()
          end, { buffer = term.bufnr, noremap = true, silent = true })
        end,
      })

      vim.keymap.set({ "n", "t" }, "<C-y>", function()
        aider:toggle()
      end, { noremap = true, silent = true, desc = "Toggle Aider terminal" })

      vim.api.nvim_create_autocmd("QuitPre", {
        group = vim.api.nvim_create_augroup("LeoToggletermQuit", { clear = true }),
        callback = function()
          for _, term in pairs(terminals.get_all(true)) do
            if term and term.job_id then
              pcall(vim.fn.jobstop, term.job_id)
            end
          end
        end,
      })

      vim.cmd([[
        cnoreabbrev <expr> wqa (getcmdtype() ==# ':' && getcmdline() ==# 'wqa') ? 'wqa!' : 'wqa'
      ]])
    end,
  },
}
