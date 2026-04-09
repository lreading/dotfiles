return {
  {
    "akinsho/toggleterm.nvim",
    config = function()
      local toggleterm = require("toggleterm")
      local terminals = require("toggleterm.terminal")
      local terminal_manager = require("terminal-manager")

      toggleterm.setup({
        open_mapping = [[<C-t>]],
        direction = "float",
        size = 50,
      })

      terminal_manager.setup()

      vim.keymap.set("n", "<leader>tm", terminal_manager.toggle_panel, {
        noremap = true,
        silent = true,
        desc = "Toggle terminal manager",
      })

      vim.api.nvim_create_autocmd("QuitPre", {
        group = vim.api.nvim_create_augroup("ToggletermQuit", { clear = true }),
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
