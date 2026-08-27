-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local marker = vim.fn.expand("~/.config/themes/current_mode")
if vim.fn.filereadable(marker) == 1 and vim.fn.readfile(marker)[1] == "light" then
  vim.opt.background = "light"
else
  vim.opt.background = "dark"
end
