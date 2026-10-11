-- ~/.config/nvim/lua/config/options.lua
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes:2" -- two columns: git change bar + diagnostic sign
vim.opt.updatetime = 300
vim.opt.wrap = false

-- Diagnostics: show the message inline, and let the worst severity win the sign
vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
})
