local function tweak_unnecessary()
  -- Break any link to Comment from the colorscheme
  vim.api.nvim_set_hl(0, "@lsp.mod.unnecessary", {})
  vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {})

  -- Now re-apply *only* stylistic hints, without fg/bg overrides.
  vim.api.nvim_set_hl(0, "@lsp.mod.unnecessary", {
    italic = true, -- or undercurl = true, etc.
  })

  vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {
    italic = true,
  })
end

tweak_unnecessary()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = tweak_unnecessary,
})
