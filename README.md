# gitlinker.nvim

> A fork of [ruifm's gitlinker.nvim](https://github.com/ruifm/gitlinker.nvim), with
> bug fix, enhancements and lots of rewrittens.

A lua plugin for [Neovim](https://github.com/neovim/neovim) to generate shareable
file permalinks (with line ranges) for git host websites. Inspired by
[tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)'s `:GBrowse`.

An example of git permalink:
<https://github.com/neovim/neovim/blob/2e156a3b7d7e25e56b03683cc6228c531f4c91ef/src/nvim/main.c#L137-L156>

Personally, I use this all the time to easily share code locations with my
co-workers.

## Regex pattern based rules

- `^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$` => `https://github.%1/%2/%3/blob/`
- `^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)%.git$` => `https://github.%1/%2/%3/blob/`

Regex patterns are introduced to map remote url to host url. For now github.com
(include both git/http protocols and github enterprise) are supported.

Please checkout [default options](https://github.com/linrongbin16/gitlinker.nvim/blob/master/lua/gitlinker.lua)
for all pattern rules, or submit PR for other git hosts!

## Requirement

- git
- neovim 0.8
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'linrongbin16/gitlinker.nvim',
    requires = 'nvim-lua/plenary.nvim',
    branch = 'master',
    config = function()
        require('gitlinker').setup()
    end,
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'linrongbin16/gitlinker.nvim', { 'branch': 'master' }
```

Then add `require('gitlinker').setup()` to your `init.lua`.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    'linrongbin16/gitlinker.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    branch = 'master',
    config = function()
        require('gitlinker').setup()
    end,
},
```

## Usage

The default key mappings are defined to open git link in browser:

- `<leader>gl` (normal/visual mode): Open in browser and print url in command line.

To disable the default key mapping, set `mapping = false` in the `setup()`
function(see [Configuration](#configuration)).

To custom key mappings, please use API `require"gitlinker".link(user_opts)`.
The `user_opts` is a table of options that override the configured options(see [Configuration](#configuration)).

```lua
vim.api.nvim_set_keymap('n', '<leader>gb',
  '<cmd>lua require"gitlinker".link({action = require"gitlinker.actions".open_in_browser})<cr>',
  { desc = "Open git link in browser" })
vim.api.nvim_set_keymap('x', '<leader>gb',
  '<cmd>lua require"gitlinker".link({action = require"gitlinker.actions".open_in_browser})<cr>',
  { desc = "Open git link in browser" })
```

### Actions

- `require"gitlinker.actions".open_in_browser`: Open git link in browser(default action).
- `require"gitlinker.actions".copy_to_clipboard`: Copy git link to clipboard.

## Configuration

Specified options in `setup()` function, they will override the default options:

```lua
require('gitlinker').setup({
  -- open_in_browser/copy_to_clipboard
  action = require("gitlinker.actions").open_in_browser,

  -- print message(git host url) in command line
  message = true,

  -- key mapping
  mapping = "<leader>gl",

  -- regex pattern based rules
  pattern_rules = {
    -- git@github.(com|*):linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
    {
      ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
      ["^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
    },
    -- http(s)://github.(com|*)/linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
    {
      ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
      ["^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
    },
  },

  -- function based rules: function(remote_url) -> host_url
  -- @param remote_url    A string value for git remote url.
  -- @return              A string value for git host url.
  custom_rules = nil,

  -- here's an example of custom_rules:
  --
  -- custom_rules = function(remote_url)
  --   local pattern_rules = {
  --     {
  --       ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
  --       ["^https://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
  --     },
  --     -- http(s)://github.(com|*)/linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
  --     {
  --       ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
  --       ["^https://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
  --     },
  --   }
  --   for _, group in ipairs(pattern_rules) do
  --     for pattern, replace in pairs(group) do
  --       if string.match(remote_url, pattern) then
  --         local result = string.gsub(remote_url, pattern, replace)
  --         return result
  --       end
  --     end
  --   end
  --   return nil
  -- end,

  -- enable debug
  debug = false,

  -- write logs to console(command line)
  console_log = true,

  -- write logs to file
  file_log = false,

  -- file name to write logs, working with `file_log=true`
  file_log_name = "gitlinker.log",
})
```

You can also pass these options to API `require"gitlinker".get_buf_range_url(user_opts)`,
they will override configured options(in `setup()`) during runtime.
