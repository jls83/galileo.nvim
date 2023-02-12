# Galileo

## Install
__NOTE:__ This plugin requires [ripgrep](https://github.com/BurntSushi/ripgrep).

Packer.nvim
```lua
use({
  'jls83/galileo.nvim',
  requires = {'nvim-telescope/telescope.nvim'},
})
```

## Quickstart
For this example, we'll assume you have a C++ project with the following structure:
```
.
├── module.cc
├── module.h
└── module_test.cc
```

In your Telescope config, add the following:
```lua
local galileo = require('galileo')
telescope.load_extension('galileo')

-- The `constants` module contains some helpers for file-name regexes.
local g_constants = require('galileo.constants')

-- We can set up some Lua strings that define items we'll reuse in the pattern
-- definitions, including a regex capture group.
local project_dir = '/path/to/my_cpp/project'
local cg = '(' .. g_constants.posix_portable_filename .. ')'

galileo.setup({
  patterns = {
    {
      -- We can use a Lua string to define a regex:
      pattern = [[/Users/jls83/other_projects/([a-z_]+)/([a-z]+)\.h]],
      -- Then use the ${N} syntax to define how we'll use the captured items in
      -- the result.
      subs = {
        project_dir .. '/${1}/${2}.cc',
        project_dir .. '/${1}/${2}_test.cc',
      },
    },
    {
      -- We can also use string concatenation to make things a bit easier to
      -- read/create.
      pattern = project_dir .. '/' .. cg .. '/' .. cg .. [[\.cc]],
      subs = {
        '/Users/jls83/other_projects/${1}/${2}.h',
        '/Users/jls83/other_projects/${1}/${2}_test.cc',
      },
    },
    {
      -- Finally, we can use named capture groups & named substitutions.
      pattern = [[/Users/jls83/other_projects/(?P<project_name>[a-z_]+)/(?P<module_name>[a-z]+)_test\.cc]],
      subs = {
        '/Users/jls83/other_projects/${project_name}/${module_name}.h',
        '/Users/jls83/other_projects/${project_name}/${module_name}.cc',
      },
    },
  },
})
```

Next, open `foo.h`, then invoke `:Telescope galileo find`. Use the Telescope picker to open any of the related files!

[![asciicast](https://asciinema.org/a/e765u8YviplJSqfBMZOhoOUgw.svg)](https://asciinema.org/a/e765u8YviplJSqfBMZOhoOUgw)
