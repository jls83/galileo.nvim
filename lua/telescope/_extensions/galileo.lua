local telescope = require("telescope")

local g_pickers = require("galileo.pickers")

return telescope.register_extension({
  exports = {
    find = g_pickers.g_telescope_find,
  },
})

