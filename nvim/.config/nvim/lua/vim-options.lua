vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.g.mapleader = " "
vim.opt.number = true
vim.wo.relativenumber = true
vim.keymap.set("n", "<leader>pv", ":Ex<CR>", { noremap = true, silent = true, desc = "Open netrw file explorer" })

-- Set up for tmux vim navigation
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>", { desc = "Move to left window" })
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>", { desc = "Move to lower window" })
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>", { desc = "Move to upper window" })
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>", { desc = "Move to right window" })

-- I always forget how to copy/paste to the system register..
vim.keymap.set("v", "<leader>Y", '"+y', { desc = "Yank selection to system clipboard" })
vim.keymap.set({ "v", "n" }, "<leader>P", '"+p', { desc = "Paste from system clipboard" })

-- Move selected lines in visual mode
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = "Move selection up" })

-- Keep the cursor centered when scrolling
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true, desc = "Scroll down and center cursor" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true, desc = "Scroll up and center cursor" })

-- Fix the current directory to the one opened with neovim:
--   eg $ ~:  nvim ~/.config/nvim will have ~ as the cwd... not ideal)
vim.cmd("autocmd VimEnter * silent! lcd %:p:h")

-- The terminal mapping for getting into normal mode is a bit much
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Make the splits more like tmux so I don't have to remember as much
vim.keymap.set("n", "<leader>%", ":vsplit<CR>", { noremap = true, silent = true, desc = "Open vertical split" })
vim.keymap.set("n", '<leader>"', ":split<CR>", { noremap = true, silent = true, desc = "Open horizontal split" })

-- More old habits die hard...
vim.keymap.set("n", "<C-a>", "ggVG", { noremap = true, silent = true, desc = "Select entire buffer" })

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
end, { noremap = true, silent = true, desc = "Close floats and send Escape" })
