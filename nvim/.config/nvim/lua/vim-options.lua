vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.g.mapleader = " "
vim.opt.number = true
vim.wo.relativenumber = true
vim.keymap.set("n", "<leader>pv", ":Ex<CR>", { noremap = true, silent = true })

-- Set up for tmux vim navigation
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")

-- I always forget how to copy/paste to the system register..
vim.keymap.set("v", "<leader>Y", '"+y')
vim.keymap.set({ "v", "n" }, "<leader>P", '"+p')

-- Move selected lines in visual mode
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

-- Keep the cursor centered when scrolling
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })

-- Fix the current directory to the one opened with neovim (eg $ ~:  nvim ~/.config/nvim will have ~ as the cwd... not ideal)
vim.cmd("autocmd VimEnter * silent! lcd %:p:h")

-- The terminal mapping for getting into normal mode is a bit much
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

-- Make the splits more like tmux so I don't have to remember as much
vim.keymap.set("n", "<leader>%", ":vsplit<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>\"", ":split<CR>", { noremap = true, silent = true })

-- More old habits die hard...
vim.keymap.set("n", "<C-a>", "ggVG", { noremap = true, silent = true })

-- Helper: close all floating windows (LSP hover, etc.)
local function close_floats()
  local closed = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative ~= "" then
      vim.api.nvim_win_close(win, true)
      closed = true
    end
  end
  return closed
end

-- In Normal mode, Ctrl-C closes floats and then behaves like Esc
vim.keymap.set("n", "<C-c>", function()
  close_floats()

  -- Feed a real <Esc> so it behaves like pressing Escape
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "n", false)
end, { noremap = true, silent = true })

