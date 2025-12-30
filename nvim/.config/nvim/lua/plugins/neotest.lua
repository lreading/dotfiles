return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-jest",
    },
    config = function()
      local neotest = require("neotest")

      neotest.setup({
        adapters = {
          require("neotest-jest")({
            jestCommand = "npx jest",
            jestConfigFile = "custom.jest.config.ts",
            env = { CI = true },
            cwd = function()
              return vim.fn.getcwd()
            end,
          }),
        },
      })

      -- Keymaps for Neotest
      vim.keymap.set("n", "<leader>tt", function()
        neotest.run.run()
      end, { desc = "Run nearest test" })

      vim.keymap.set("n", "<leader>tf", function()
        neotest.run.run(vim.fn.expand("%"))
      end, { desc = "Run file tests" })

      vim.keymap.set("n", "<leader>ts", function()
        neotest.summary.toggle()
      end, { desc = "Toggle test summary" })

      vim.keymap.set("n", "<leader>to", function()
        neotest.output.open({ enter = true })
      end, { desc = "Open test output" })

      vim.keymap.set("n", "<leader>tw", function()
        neotest.watch.toggle(vim.fn.expand("%"))
      end, { desc = "Toggle watch mode" })

      vim.keymap.set("n", "<leader>td", function()
        neotest.run.run({ strategy = "dap" })
      end, { desc = "Debug test" })
    end,
  },
}
