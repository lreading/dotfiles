return {
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      alt = { "BUG", "LEO" },
    },
    config = function()
      local comments = require("todo-comments")

      vim.keymap.set("n", "<leader>ft", ":TodoTelescope<CR>", { noremap = true, silent = true })

      -- vim.keymap.set("n", "<leader>tn", function()
      --   comments.jump_next()
      -- end, { desc = "Next todo comment" })

      -- vim.keymap.set("n", "<leader>tp", function()
      --   comments.jump_prev()
      -- end, { desc = "Previous todo comment" })

      comments.setup()
    end,
  },
}
