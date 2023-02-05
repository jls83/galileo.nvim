local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local telescope_utils = require("telescope.utils")

local utils = require("galileo.utils")

local M = {}

local build_find_command = function(opts)
  local default_opts = {
    -- TODO: Eh.
    include_hidden = true,
    ignore_files = true,
    absolute_path = true,
    glob = true,
  }

  -- TODO: merge opts
  local local_opts = vim.tbl_deep_extend("force", default_opts, opts)

  -- TODO: Do we need to allow --type changes?
  local find_command = { "fd", "--type", "f", "--color", "never" }

  if local_opts.include_hidden then
    find_command[#find_command + 1] = "--hidden"
  end

  if not local_opts.ignore_files then
    find_command[#find_command + 1] = "--no-ignore"
  end

  if local_opts.absolute_path then
    find_command[#find_command + 1] = "--absolute-path"
  end

  if local_opts.base_directory ~= nil then
    vim.list_extend(find_command, { "--base-directory", local_opts.base_directory })
  end

  if local_opts.depth ~= nil then
    vim.list_extend(find_command, { "--max-depth", tostring(local_opts.depth) })
  end

  if local_opts.glob then
    vim.list_extend(find_command, { "--glob", local_opts.search_pattern })
  else
    vim.list_extend(find_command, { "--regex", local_opts.search_pattern })
  end

  local_opts.entry_maker = local_opts.entry_maker or make_entry.gen_from_file(local_opts)

  return find_command
end

M.find = function(opts)
  local has_fd = vim.fn.executable("fd")

  if not has_fd then
    telescope_utils.notify("galileo.find", {
      msg = "You need to install fd",
      level = "ERROR",
    })
    return
  end

  local find_command = build_find_command(opts)

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
