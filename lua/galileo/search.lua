local Job = require('plenary.job')
local a = require('plenary.async')

-- TODO: Replace this with a library?
local random = math.random
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

M = {}

M.job_def_factory_builder = function(opts, tx)
  local job_def_factory = function(filename)
    local job_defs = {}

    -- If `what_thing_who` is a function, add it to a table to use later.
    local sub_functions = {}

    for _, what_thing_who in pairs(opts.subs) do
      -- TODO: Fix docs.
      -- If the sub has a name, use that as the data_key. Otherwise, swap in
      -- `ITEM_N`, where `N` is the index of the sub in the input table.
      -- local data_key = sub
      -- if type(sub) ~= 'string' then
      --   data_key = "ITEM_" .. tostring(sub)
      -- end
      local data_key = uuid()

      local result_pattern = ""

      print("Sub type: " .. type(what_thing_who))

      if type(what_thing_who) == "string" then
        result_pattern = what_thing_who
      elseif type(what_thing_who) == "function" then
        -- TODO: Explain!
        local func_info = debug.getinfo(what_thing_who)
        if func_info.isvararg then
          error("Functions must not be variable arity")
        end

        local arg_list = {}

        for i = 1, func_info.nparams, 1 do
          local arg = "$" .. i
          table.insert(arg_list, arg)
        end

        print('Inserting a func for ' .. data_key)
        sub_functions[data_key] = what_thing_who

        -- TODO: Better delimiter? Use constant?
        result_pattern = table.concat(arg_list, " ")
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

    return job_defs, sub_functions
  end

  return job_def_factory
end

M.search = function(filename, t)
  local sender, receiver = a.control.channel.mpsc()

  local all_jobs = {}

  local sub_functions = {}

  for _, thing in pairs(t) do
    local job_def_factory = M.job_def_factory_builder(thing, sender)
    local job_defs, inner_sub_functions = job_def_factory(filename)

    for data_key, fn in pairs(inner_sub_functions) do
      sub_functions[data_key] = fn
    end

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
    for data_key, result in pairs(job_output) do
      -- Only include subs if they had a result.
      if #result == 0 then
        goto continue
      end

      local blah = {}
      blah['result'] = result[1]


      local fn = sub_functions[data_key]
      if fn ~= nil then
        blah['fn'] = fn
      else
        print('Did not find fn for ' .. data_key)
      end

      table.insert(results, blah)

      ::continue::
    end
  end

  return results
end

return M
