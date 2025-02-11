local M = {}

M.zoomed = false
M.original_height = nil
M.original_width = nil

function M.toggle_zoom()
  local current_win = vim.api.nvim_get_current_win()

  if M.zoomed then
    -- Restore original window size
    vim.api.nvim_win_set_height(current_win, M.original_height)
    vim.api.nvim_win_set_width(current_win, M.original_width)
    M.zoomed = false
  else
    -- Save current window size
    M.original_height = vim.api.nvim_win_get_height(current_win)
    M.original_width = vim.api.nvim_win_get_width(current_win)

    -- Maximize window
    vim.cmd("resize | vertical resize")
    M.zoomed = true
  end
end

-- Set keymap to <Leader>m
vim.keymap.set("n", "<Leader>z", M.toggle_zoom, { noremap = true, silent = true })

return M
