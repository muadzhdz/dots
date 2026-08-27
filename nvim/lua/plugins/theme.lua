local function apply_monochrome()
  vim.opt.background = "dark"
  local fg = "#ffffff"
  local bg = "#000000"
  local dim = "#888888"
  local border = "#222222"
  local sel = "#1a1a1a"

  vim.api.nvim_set_hl(0, "Normal", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "NormalNC", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = border, bg = bg })
  vim.api.nvim_set_hl(0, "FloatTitle", { fg = fg, bg = bg, bold = true })
  vim.api.nvim_set_hl(0, "LineNr", { fg = dim })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = fg, bold = true })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = sel })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = bg })
  vim.api.nvim_set_hl(0, "StatusLine", { fg = fg, bg = sel })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = dim, bg = bg })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = border })
  vim.api.nvim_set_hl(0, "Pmenu", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "PmenuSel", { fg = fg, bg = sel, bold = true })
  vim.api.nvim_set_hl(0, "PmenuBorder", { fg = border, bg = bg })

  -- Dashboard highlights (Snacks / Dashboard / Alpha)
  vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = fg, bold = true })
  vim.api.nvim_set_hl(0, "SnacksDashboardIcon", { fg = fg })
  vim.api.nvim_set_hl(0, "SnacksDashboardDesc", { fg = fg })
  vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = dim, bold = true })
  vim.api.nvim_set_hl(0, "SnacksDashboardFooter", { fg = dim })
  vim.api.nvim_set_hl(0, "SnacksDashboardSpecial", { fg = fg })
  vim.api.nvim_set_hl(0, "SnacksDashboardDir", { fg = dim })
  vim.api.nvim_set_hl(0, "SnacksDashboardFile", { fg = fg })

  -- Telescope / NeoTree / WhichKey
  vim.api.nvim_set_hl(0, "TelescopeNormal", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = border, bg = bg })
  vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = fg, bg = sel })
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { fg = border })
  vim.api.nvim_set_hl(0, "WhichKey", { fg = fg })
  vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = dim })
  vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = fg })

  -- Syntax highlights (Pure Clean Monochrome)
  vim.api.nvim_set_hl(0, "Comment", { fg = dim, italic = true })
  vim.api.nvim_set_hl(0, "Constant", { fg = fg })
  vim.api.nvim_set_hl(0, "String", { fg = "#cccccc" })
  vim.api.nvim_set_hl(0, "Identifier", { fg = fg })
  vim.api.nvim_set_hl(0, "Function", { fg = fg, bold = true })
  vim.api.nvim_set_hl(0, "Statement", { fg = fg, bold = true })
  vim.api.nvim_set_hl(0, "Keyword", { fg = fg, bold = true })
  vim.api.nvim_set_hl(0, "Type", { fg = fg, bold = true })
  vim.api.nvim_set_hl(0, "Special", { fg = fg })
end

vim.api.nvim_create_user_command("SyncTheme", function()
  apply_monochrome()
end, {})

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme", "UIEnter" }, {
  callback = function()
    apply_monochrome()
  end,
})

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        apply_monochrome()
      end,
    },
  },
}
