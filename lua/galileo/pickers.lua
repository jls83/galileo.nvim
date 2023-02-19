local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")

local galileo = require("galileo")
local g_search = require("galileo.search")
local g_constants = require("galileo.constants")

local M = {}

-- TODO: override other `select_` behavior?
M._select_default = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()

  -- `action_set.select` is the default behavior for the picker. Use that if we
  -- don't have a result, or we don't have a `fn`(i.e. we _do_ have a filename).
  if selection == nil or selection.fn == nil then
    action_set.select(prompt_bufnr, "default")
    return
  end

  actions.close(prompt_bufnr)
  -- TODO: do this somewhere else?
  local fn_args = vim.split(
    selection.result,
    g_constants.FUNCTION_RESULT_DELIMITER
  )

  local fn = selection.fn

  -- TODO: Use result?
  fn(unpack(fn_args))
end

M._transform_search_results = function(search_results)
  local res = {}
  for _, v in pairs(search_results) do
    local finder_obj = {
      sub_name = v.sub_name,
      result = v.result,
      fn = v.fn,
    }
    table.insert(res, finder_obj)
  end

  return res
end

-- NOTE: This is absolutely not the best implementation for this!
M._get_text_from_finder_result = function(find_result)
  local prefix
  if type(find_result.sub_name) == "string" then
    prefix = find_result.sub_name
  elseif find_result.fn ~= nil then
    prefix = "Function"
  else
    prefix = "File"
  end

  if find_result.fn ~= nil then
    -- TODO: do this somewhere else?
    local fn_args = vim.split(
      find_result.result,
      g_constants.FUNCTION_RESULT_DELIMITER
    )
    return prefix .. ': function(' .. table.concat(fn_args, ', ') .. ')'
  else
    return prefix .. ': ' .. find_result.result
  end
end

M.g_telescope_find = function(outer_opts)
  local opts = outer_opts or {}

  local search_results = g_search.search(
    vim.fn.expand("%:p"),
    galileo.config.patterns
  )

  local entry_maker
  if opts.entry_maker then
    entry_maker = opts.entry_maker
  else
    entry_maker = function(entry)
      local text = M._get_text_from_finder_result(entry)
      return {
        value = entry,
        text = text,
        display = text,
        ordinal = text,
        filename = entry.result,
        result = entry.result,
        fn = entry.fn,
      }
    end
  end

  -- `previewer` will be `nil` unless explicitly set at setup.
  local previewer = opts.previewer

  local picker = pickers.new(opts, {
    prompt_title = "Galileo",
    finder = finders.new_table({
      results = M._transform_search_results(search_results),
      entry_maker = entry_maker,
    }),
    previewer = previewer,
    sorter = conf.generic_sorter(opts),
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
