local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("This extension requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end

-- TODO: check for `rg`

local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")

local galileo = require('galileo')
local g_search = require('galileo.search')

local transform_find_results = function(find_results)
  local res = {}
  for k, v in pairs(find_results) do
  -- TODO: figure out the right thing to show?
    local finder_obj = {
      text = k .. ' ' .. v,
      filename = v,
    }
    table.insert(res, finder_obj)
  end

  return res
end

local g_telescope_find = function(opts)
  local opts = opts or {}

  local find_results = g_search.search(
    vim.fn.expand('%:p'),
    galileo.config.patterns
  )

  local picker = pickers
    .new(opts, {
        prompt_title = "Galileo",
        finder = finders.new_table({
          results = transform_find_results(find_results),
          entry_maker = function(entry)
            return make_entry.set_default_entry_mt({
              value = entry,
              text = entry.text,
              display = entry.text, -- TODO
              ordinal = entry.text,
              filename = entry.filename,
            }, opts)
          end,
        }),
        previewer = conf.file_previewer(opts),
        sorter = conf.file_sorter(opts),
    })
  picker:find()
end

return telescope.register_extension({
  exports = {
    find = g_telescope_find,
  },
})

