vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.g.mapleader = " "
vim.opt.number = true
vim.wo.relativenumber = true
vim.keymap.set("n", "<leader>pv", ":Ex<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")

-- I always forget how to copy/paste to the system register..
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set({"v", "n"}, "<leader>p", '"+p')

