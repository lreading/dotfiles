return {
  {
    "tpope/vim-commentary",
    config = function()
      vim.keymap.set("n", "<C-_>", ":Commentary<CR>", { noremap = true, silent = true })
      vim.keymap.set("v", "<C-_>", ":Commentary<CR>", { noremap = true, silent = true })
    end,
  },
}

