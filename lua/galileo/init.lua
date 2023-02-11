local M = {}

M.config = {
  patterns = {},
}


M.setup = function(config)
  if config.patterns == nil then
    -- TODO: Alert
    return
  end
  M.config = vim.tbl_extend("force", M.config, config or {})
end

return M
