local telescope = require("telescope")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local galileo = require('galileo')
local g_search = require('galileo.search')

local transform_find_results = function(find_results)
  local res = {}
  for k, v in pairs(find_results) do
    local text
    if type(v.sub_name) == "number" and v.fn ~= nil then
      text = 'Function: ' .. v.result
    elseif type(v.sub_name) == "number" then
      text = v.result
    else -- if type(v.sub_name) == "string"
      text = tostring(v.sub_name)
    end

  -- TODO: figure out the right thing to show
    local finder_obj = {
      text = text,
      -- text = k .. ' ' .. v.result,
      result = v.result,
      fn = v.fn,
    }
    table.insert(res, finder_obj)
  end

  return res
end

-- TODO: override other `select_` behavior?
local select_default = function(prompt_bufnr)
  actions.close(prompt_bufnr)
  local selection = action_state.get_selected_entry()

  print(vim.inspect(selection))

  if selection == nil then
    return
  elseif selection.fn == nil then
    -- TODO: Doc, consider this. maybe key on `filename`?
    vim.cmd('edit' .. selection.filename)
  else
    -- TODO: change name
    local fn_args = vim.split(selection.result, " ")
    print(vim.inspect(fn_args))

    local fn = selection.fn
    print(vim.inspect(fn))

    local foo = fn(unpack(fn_args))
    print(vim.inspect(foo))
  end
end

local g_telescope_find = function(opts)
  local opts = opts or {}

  local find_results = g_search.search(
    vim.fn.expand('%:p'),
    galileo.config.patterns
  )

  local entry_maker
  if opts.entry_maker then
    entry_maker = opts.entry_maker
  else
    entry_maker = function(entry)
      return {
        value = entry,
        text = entry.text,
        display = entry.text, -- TODO
        ordinal = entry.text,
        filename = entry.result,
        result = entry.result,
        fn = entry.fn,
      }
    end
  end


  local picker = pickers
    .new(opts, {
        prompt_title = "Galileo",
        finder = finders.new_table({
          results = transform_find_results(find_results),
          entry_maker = entry_maker,
        }),
        -- previewer = conf.file_previewer(opts),
        sorter = conf.file_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            select_default(prompt_bufnr)
          end)
          return true
        end,
    })
  picker:find()
end

return telescope.register_extension({
  exports = {
    find = g_telescope_find,
  },
})

