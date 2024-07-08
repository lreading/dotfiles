return {
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<C-t>]],
        direction = "float",
        size = 50
      })
    end
  }
}
