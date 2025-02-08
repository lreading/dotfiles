return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")

      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "node_modules" },
          find_command = { "git", "ls-files", "--recurse-submodules" }, -- Only show Git-tracked files
        },
        pickers = {
          find_files = {
            find_command = { "git", "ls-files", "--recurse-submodules" },
            cwd = vim.fn.getcwd(),
          },
          live_grep = {
            cwd = vim.fn.getcwd(),
            vimgrep_arguments = {
              "rg",
              "--color=never",
              "--no-heading",
              "--with-filename",
              "--line-number",
              "--column",
              "--smart-case",
              "--hidden",
              "--no-ignore",
              "--glob",
              "!.git/*",
              "--glob",
              "!node_modules/*",
              "--glob",
              "!dist/*",
            },
          },
        },
      })

      -- Keymaps
      vim.keymap.set("n", "<C-p>", function()
        builtin.find_files({ cwd = vim.fn.getcwd() })
      end, {})

      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})

      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>gg", function()
        builtin.git_files({ cwd = vim.fn.getcwd() })
      end, {})

      vim.keymap.set("n", "<leader>fs", function()
        builtin.live_grep({ search_dirs = { "src", "tests", "*" }, cwd = vim.fn.getcwd() })
      end, {})
    end,
  },
}

