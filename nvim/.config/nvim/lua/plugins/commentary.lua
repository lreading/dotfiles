return {
  {
    "tpope/vim-commentary",
    config = function()
      vim.keymap.set("n", "<C-_>", ":Commentary<CR>", { noremap = true, silent = true, desc = "Toggle comment on current line" })
      vim.keymap.set("v", "<C-_>", ":Commentary<CR>", { noremap = true, silent = true, desc = "Toggle comment on selection" })
    end,
  },
}
