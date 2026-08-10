local spec_path = vim.fn.expand("~/.config/matugen/generated/neovim-theme-spec.lua")
if vim.fn.filereadable(spec_path) == 1 then
  local spec = dofile(spec_path)
  if type(spec) == "table" and spec[1] and type(spec[1].config) == "function" then
    spec[1].config()
  end
else
  vim.g.colors_name = "matugen"
end
