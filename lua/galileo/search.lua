local Job = require('plenary.job')
local a = require('plenary.async')

local g_constants = require("galileo.constants")
local g_log = require("galileo.log")

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

-- Get debug info for the `fn` function, then set up a `result_pattern` with an
-- entry for each arg in the function.
-- NOTE: Functions with variable arguments (e.g. `function(a, ...)`) cannot be
-- used here.
M._build_function_result_pattern = function(fn)
  local func_info = debug.getinfo(fn)
  if func_info.isvararg then
    error("Functions must not be variable arity")
  end

  local arg_list = {}

  for i = 1, func_info.nparams, 1 do
    local arg = "$" .. i
    table.insert(arg_list, arg)
  end

  return table.concat(arg_list, g_constants.FUNCTION_RESULT_DELIMITER)
end

M.job_def_factory_builder = function(opts, tx)
  local job_def_factory = function(filename)
    local job_defs = {}
    local data_key_to_sub = {}
    local sub_functions = {}

    for sub_name, on_match in pairs(opts.subs) do
      -- Set up a unique key for each sub. This allows for "joining" any
      -- functions & labels later.
      local data_key = uuid()
      data_key_to_sub[data_key] = sub_name

      local result_pattern

      if type(on_match) == "string" then
        result_pattern = on_match
      elseif type(on_match) == "function" then
        result_pattern = M._build_function_result_pattern(on_match)
        sub_functions[data_key] = on_match
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
        on_start = function()
          g_log.debug("Job start:", data_key, opts.pattern, result_pattern)
        end,
        -- Use `on_exit` to guarantee we write to the `sender` for every job.
        on_exit = function(j, code)
          local job_result = j:result()
          local found_result_message
          if #job_result == 0 then
            found_result_message = "(No results)"
          else
            found_result_message = "(Found results)"
          end
          tx.send({[data_key] = job_result})
          g_log.debug(("Job complete (" .. code .. "):"), data_key, found_result_message)
        end,
      }

      table.insert(job_defs, job_def)
    end

    return job_defs, sub_functions, data_key_to_sub
  end

  return job_def_factory
end

M.search = function(filename, rules)
  local sender, receiver = a.control.channel.mpsc()

  local all_jobs = {}
  local sub_functions = {}
  local data_key_to_sub = {}

  for _, rule in pairs(rules) do
    local job_def_factory = M.job_def_factory_builder(rule, sender)
    local job_defs, inner_sub_functions, inner_data_key_to_sub = job_def_factory(filename)

    for data_key, fn in pairs(inner_sub_functions) do
      sub_functions[data_key] = fn
    end

    for data_key, sub in pairs(inner_data_key_to_sub) do
      data_key_to_sub[data_key] = sub
    end

    for _, job_def in pairs(job_defs) do
      local job = Job:new(job_def)
      table.insert(all_jobs, job)
      job:start()
    end
  end

  local _, code = Job.join(unpack(all_jobs))
  if code ~= nil then
    error("rg jobs failed")
  end

  local results = {}

  -- If we "over-read" from the receiver, we get a Lua error. Use the number of
  -- jobs to control the number of iterations.
  for _ = 1, #all_jobs, 1 do
    local job_output = receiver.recv()
    for data_key, job_result in pairs(job_output) do
      -- Only include subs if they had a result.
      if #job_result == 0 then
        goto continue
      end

      local result = {}
      result['result'] = job_result[1] -- TODO: better name?
      result['sub_name'] = data_key_to_sub[data_key]

      local fn = sub_functions[data_key]
      if fn ~= nil then
        result['fn'] = fn
      end

      table.insert(results, result)

      ::continue::
    end
  end

  return results
end

return M
