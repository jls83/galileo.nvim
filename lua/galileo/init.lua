local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("This extension requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end

if vim.fn.executable("rg") ~= 1 then
  error("This extension requires ripgrep (https://github.com/BurntSushi/ripgrep)")
end

local M = {}

M.config = {
  patterns = {},
}


M.setup = function(config)
  if config.patterns == nil then
    error("You must pass in a `patterns` key.")
    return
  end
  M.config = vim.tbl_extend("force", M.config, config or {})
end

return M
