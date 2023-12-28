# Neovim Config

This is largely based on [ThePrimeagen's 0 to LSP Neovim Setup](https://www.youtube.com/watch?v=w7i4amO_zaE).  There are a small number of things I've changed to suit my needs.  I'm by no means a neovim expert: at the time of writing, I'm just starting to use it to see if it will work for me long-term.  You've been warned!

After these files are copied (using setup.sh if you prefer), you will need to open [lua/thenerdyhick/packer.lua](./lua/thenerdyhick/packer.lua) in neovim, and run a couple of commands:
`nvim ./lua/thenerdyhick/packer.lua`
`:so`
`:PackerSync`

Neovim should be configured now.

