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
          -- make .git hidden but always show .github
          filtered_items = {
            visible = false, -- start with hidden items actually hidden
            show_hidden_count = true,
            hide_dotfiles = true,
            hide_gitignored = false,
            hide_by_name = {
              ".git",
            },
            always_show = {
              ".github",
            },
          },

          window = {
            mappings = {
              ["<cr>"] = "conditional_enter",
              ["H"] = "toggle_hidden",
              ["t"] = "open_tabnew",
              ["d"] = "add_directory",
              ["D"] = "delete",
              ["R"] = "rename",
              ["?"] = "show_help",
              ["%"] = "add",
            },
          },

          commands = {
            conditional_enter = function(state)
              local node = state.tree:get_node()
              if not node then
                return
              end

              -- The "(n hidden items)" line is a special "message" node.
              -- For those, toggle hidden instead of trying to open.
              if node.type == "message" then
                require("neo-tree.sources.filesystem.commands").toggle_hidden(state)
              else
                require("neo-tree.sources.filesystem.commands").open(state)
              end
            end,
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
    end,
  },
}
