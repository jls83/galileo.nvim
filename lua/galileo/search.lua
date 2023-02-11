local Job = require('plenary.job')
local a = require('plenary.async')

M = {}

M.job_def_factory_builder = function(opts, tx)
  return (function(filename)
    local job_defs = {}

    for sub, result_pattern in pairs(opts.subs) do
      -- If the sub has a name, use that as the data_key. Otherwise, swap in
      -- `ITEM_N`, where `N` is the index of the sub in the input table.
      local data_key = sub
      if type(sub) ~= 'string' then
        data_key = "ITEM_" .. tostring(sub)
      end

      local job_def = {
        -- Piping the filename into `rg` allows us to match & replace using all
        -- of ripgrep's features.
        writer = filename,
        command = 'rg',
        args = {
          opts.pattern,
          '-r',
          result_pattern,
        },
        -- Use `on_exit` to guarantee we write to the `sender` for every job.
        on_exit = function(j)
          tx.send({[tostring(data_key)] = j:result()})
        end,
      }

      table.insert(job_defs, job_def)
    end

    return job_defs
  end)
end

M.search = function(filename, t)
  local sender, receiver = a.control.channel.mpsc()

  local all_jobs = {}

  for _, thing in pairs(t) do
    local job_def_factory = M.job_def_factory_builder(thing, sender)
    local job_defs = job_def_factory(filename)

    for _, job_def in pairs(job_defs) do
      local job = Job:new(job_def)
      table.insert(all_jobs, job)
      job:start()
    end
  end

  Job.join(unpack(all_jobs))

  local results = {}

  -- If we "over-read" from the receiver, we get a Lua error. Use the number of
  -- jobs to control the number of iterations.
  for _ = 1, #all_jobs, 1 do
    local job_output = receiver.recv()
    for sub, result in pairs(job_output) do
      -- Only include subs if they had a result.
      if #result ~= 0 then
        results[sub] = result[1]
      end
    end
  end

  return results
end

local things = {
  {
    pattern = [[/Users/jls83/other_projects/([a-z_]+)/([a-z]+)\.h]],
    subs = {
      '/Users/jls83/other_projects/${1}/${2}.cc',
      '/Users/jls83/other_projects/${1}/${2}_test.cc',
    },
  },
  {
    pattern = [[/Users/jls83/other_projects/([a-z_]+)/([a-z]+)\.cc]],
    subs = {
      '/Users/jls83/other_projects/${1}/${2}.h',
      '/Users/jls83/other_projects/${1}/${2}_test.cc',
    },
  },
  {
    pattern = [[/Users/jls83/other_projects/([a-z_]+)/([a-z]+)_test\.cc]],
    subs = {
      '/Users/jls83/other_projects/${1}/${2}.h',
      '/Users/jls83/other_projects/${1}/${2}.cc',
    },
  },
}

M.search_default = function(filename)
  return M.search(filename, things)
end

return M
