return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      panel = {
        enabled = false,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        -- keep Tab normal when no suggestion is present
        trigger_on_accept = false,
        keymap = {
          accept = "<Tab>", -- like copilot.vim
          accept_word = false,
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
    },
    config = function(_, opts)
      require("copilot").setup(opts)

      -- Hide Copilot suggestions when leaving insert / changing mode
      vim.api.nvim_create_autocmd({ "InsertLeave", "ModeChanged" }, {
        callback = function()
          local ok, suggestion = pcall(require, "copilot.suggestion")
          if ok then
            suggestion.dismiss()
          end
        end,
      })
    end,
  },
}
