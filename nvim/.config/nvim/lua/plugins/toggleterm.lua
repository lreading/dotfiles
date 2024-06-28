return {
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<C-t>]],
        direction = "vertical",
        size = 50
      })
    end
  }
}
