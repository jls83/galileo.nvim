local M = {}

-- See this Wikipedia link for a table of filename limitations.
-- https://en.wikipedia.org/wiki/Filename#Comparison_of_filename_limitations
M.posix_portable_filename = '[a-zA-Z0-9._][a-zA-Z0-9._-]*'

return M
