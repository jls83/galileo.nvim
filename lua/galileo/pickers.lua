local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local galileo = require("galileo")
local g_search = require("galileo.search")
local g_constants = require("galileo.constants")

local M = {}

-- TODO: override other `select_` behavior?
M._select_default = function(prompt_bufnr)
  actions.close(prompt_bufnr)
  local selection = action_state.get_selected_entry()

  if selection == nil then
    return
  elseif selection.fn == nil then
    -- TODO: Doc, consider this. maybe key on `filename`?
    -- TODO: use action_set from telescope for this:
    -- https://github.com/nvim-telescope/telescope.nvim/blob/203bf5609137600d73e8ed82703d6b0e320a5f36/lua/telescope/actions/set.lua#L91-L97
    vim.cmd("edit" .. selection.filename)
  else
    local fn_args = vim.split(
      selection.result,
      g_constants.FUNCTION_RESULT_DELIMITER
    )

    local fn = selection.fn

    -- TODO: Use result?
    fn(unpack(fn_args))
  end
end

M._transform_find_results = function(find_results)
  local res = {}
  for _, v in pairs(find_results) do
    local text
    if type(v.sub_name) == "number" and v.fn ~= nil then
      text = "Function: " .. v.result
    elseif type(v.sub_name) == "number" then
      text = v.result
    else -- if type(v.sub_name) == "string"
      text = tostring(v.sub_name)
    end

  -- TODO: figure out the right thing to show
    local finder_obj = {
      text = text,
      result = v.result,
      fn = v.fn,
    }
    table.insert(res, finder_obj)
  end

  return res
end

M.g_telescope_find = function(opts)
  local opts = opts or {}

  local find_results = g_search.search(
    vim.fn.expand("%:p"),
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
          results = M._transform_find_results(find_results),
          entry_maker = entry_maker,
        }),
        -- previewer = conf.file_previewer(opts),
        sorter = conf.file_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            M._select_default(prompt_bufnr)
          end)
          return true
        end,
    })
  picker:find()
end

return M
