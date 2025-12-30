vim.g.python3_host_prog = vim.fn.expand('~/.local/share/pipx/venvs/pynvim/bin/python3')
vim.g.ruby_host_prog = '/usr/bin/ruby'
vim.g.loaded_perl_provider = 0

require("vim-options")
require("zoom")
require("logrotate")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
vim.opt.termguicolors = true

require("lazy").setup("plugins", {
  opts = {
    rocks = {
      enabled = false,
    }
  }
})

-- Rust analyzer is very... firm when it comes to unused / unnecessary code
-- This can be annoying when creating a new file, because usually you just
-- want to start writing code and will integrate it later as opposed to 
-- throwing stubs all over the place to ensure it's "used".
-- Rather than fighting it, we just change the display to use italics for
-- unnecessary code to give a more subtle hint that this isn't used yet
-- This also allows us to continue to use the default settings for
-- rust-analyzer without dropping this specific diagnostic.
--
-- This should be loaded AFTER any themes
require("unnecessary-colors")

