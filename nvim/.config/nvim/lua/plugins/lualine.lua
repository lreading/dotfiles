return {
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      local function unsaved_buffers_indicator()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_option(buf, "modified") then
            return "⚠️ Unsaved Buffers!"
          end
        end
        return ""
      end

      require("lualine").setup({
        options = {
          theme = "dracula",
        },
        sections = {
          lualine_c = {
            {"filename", path = 1, symbols = {modified = "[+]", readonly = "[-]"}},
            {unsaved_buffers_indicator},
          },
        },
      })
    end
  }
}

