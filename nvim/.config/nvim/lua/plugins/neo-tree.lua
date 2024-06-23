return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      vim.keymap.set("n", "<leader>tr", ":Neotree filesystem reveal left toggle=true<CR>")
      require("neo-tree").setup({
        filesystem = {
          window = {
            mappings = {
              ["<cr>"] = "open",
              ["t"] = "open_tabnew",
              ["d"] = "add_directory",
              ["D"] = "delete",
              ["R"] = "rename",
              ["?"] = "show_help",
              ["%"] = "add",
            },
          },
          hijack_netrw_behavior = "disabled",
          use_libuv_file_watcher = true,
        },
        auto_open = false,
        auto_close = true,
      })

      local function disable_auto_open()
        vim.cmd([[
          augroup NeoTreeAutoOpen
            autocmd!
            autocmd BufEnter * if &buftype == '' | silent! NeoTreeClose | endif
          augroup END
        ]])
      end

      disable_auto_open()
    end
  }
}
