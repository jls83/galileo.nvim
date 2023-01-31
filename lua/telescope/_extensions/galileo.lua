local has_telescope, _ = pcall(require, "telescope")

if not has_telescope then
  error("This extension requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end

local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local utils = require("telescope.utils")

-- TODO: move this
local M = {}

local function make_glob()
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

M.find = function(opts)
  local has_fd = vim.fn.executable("fd")

  if not has_fd then
    utils.notify("builtin.find_files", {
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
  find_command[#find_command + 1] = "--full-path"
  -- TODO: maybe use the make_entry to lop off the beginning?
  find_command[#find_command + 1] = "--absolute-path"

  -- TODO: error handling
  vim.list_extend(find_command, { "--base-directory", opts.base_directory })

  -- Search pattern
  find_command[#find_command + 1] = opts.search_pattern

  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

  -- TODO: log this
  -- print(table.concat(find_command, " "))

  pickers
    .new(opts, {
        prompt_title = "Galileo",
        finder = finders.new_oneshot_job(find_command, opts),
        previewer = conf.file_previewer(opts),
        sorter = conf.file_sorter(opts),
    })
    :find()
end

-- return M
--
-- M.find({
--   search_pattern = "**/app.html",
--   base_directory = "/Users/jls83/other_projects/cpp_interface_junk",
-- })
M.find(make_glob())
