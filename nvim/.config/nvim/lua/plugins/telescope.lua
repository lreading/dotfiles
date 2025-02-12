return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")

      -- Function to check if current directory is a Git repo
      local function is_git_repo()
        vim.fn.system("git rev-parse --is-inside-work-tree")
        return vim.v.shell_error == 0
      end

      -- Determine find command based on whether it's a Git repo
      local function get_find_command()
        if is_git_repo() then
          return { "git", "ls-files", "--recurse-submodules" }
        else
          -- Use `fd` if available, otherwise fallback to `find`
          if vim.fn.executable("fd") == 1 then
            return { "fd", "--type", "f", "--hidden", "--exclude", ".git" }
          else
            return { "find", ".", "-type", "f", "-not", "-path", "*/.git/*" }
          end
        end
      end

      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "node_modules" },
        },
        pickers = {
          find_files = {
            find_command = get_find_command(),
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
        builtin.find_files({ find_command = get_find_command(), cwd = vim.fn.getcwd() })
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

