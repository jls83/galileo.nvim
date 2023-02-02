local M = {}

M.make_glob = function()
  -- local current_file = vim.fn.expand("%:p")
  -- local extension = vim.fn.expand("%:e")
  -- NOTE: This is not the "real" base_directory
  local base_directory = vim.fn.expand("%:h")
  local no_extension = vim.fn.expand("%:r")

  local search_pattern = "**/" .. no_extension .. "*"

  return {
    base_directory = base_directory,
    search_pattern = search_pattern,
  }

end

return M
