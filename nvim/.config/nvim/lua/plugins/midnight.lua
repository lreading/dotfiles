return {
  {
    "lreading/midnight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme midnight]])
      vim.cmd([[hi Normal guibg=NONE ctermbg=NONE]])
    end,
  },
}
