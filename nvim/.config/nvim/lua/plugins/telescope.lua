return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      require("telescope").setup({
        defaults = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob",
            "!.git/*",
            "--glob",
            "!node_modules/*",
          },
          file_ignore_patterns = { "node_modules" },
          find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
        },
      })

      vim.keymap.set("n", "<C-p>", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>gg", builtin.git_files, {})
      vim.keymap.set("n", "<leader>fs", function()
        builtin.live_grep({ search_dirs = { "src", "tests", "*" } })
      end, {})
    end,
  },
}
