return {
  {
    "midnight.nvim",
    dir = "/home/leo/dev/midnight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme midnight]])
    end
  }
}

