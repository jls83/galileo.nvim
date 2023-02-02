local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local utils = require("telescope.utils")

local M = {}

M.find = function(opts)
  local has_fd = vim.fn.executable("fd")

  if not has_fd then
    utils.notify("galileo.find", {
      msg = "You need to install fd",
      level = "ERROR",
    })
    return
  end

  local find_command = { "fd", "--type", "f", "--color", "never" }

  -- TODO: Change this to use `opts`
  find_command[#find_command + 1] = "--hidden"
  find_command[#find_command + 1] = "--no-ignore"
  -- find_command[#find_command + 1] = "--follow"
  find_command[#find_command + 1] = "--glob"
  -- find_command[#find_command + 1] = "--full-path"
  -- TODO: maybe use the make_entry to lop off the beginning?
  -- find_command[#find_command + 1] = "--absolute-path"

  -- TODO: error handling
  -- vim.list_extend(find_command, { "--base-directory", opts.base_directory })
  vim.list_extend(find_command, { "-d", 1 })

  -- Search pattern
  find_command[#find_command + 1] = opts.search_pattern

  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

  -- TODO: log this
  print(vim.inspect(find_command))

  local picker = pickers
    .new(opts, {
        prompt_title = "Galileo",
        finder = finders.new_oneshot_job(find_command, opts),
        previewer = conf.file_previewer(opts),
        sorter = conf.file_sorter(opts),
    })
  picker:find()
end

return M
