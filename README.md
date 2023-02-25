# gitlinker.nvim

> A fork of [ruifm's gitlinker.nvim](https://github.com/ruifm/gitlinker.nvim), with
> bug fix, enhancements and lots of rewrittens.

A lua plugin for [Neovim](https://github.com/neovim/neovim) to generate sharable
file permalinks (with line ranges) for git host websites. Inspired by
[tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)'s `:GBrowse`.

An example of git permalink:
<https://github.com/neovim/neovim/blob/2e156a3b7d7e25e56b03683cc6228c531f4c91ef/src/nvim/main.c#L137-L156>

Personally, I use this all the time to easily share code locations with my
co-workers.

## Break changes & updates

1. Cross-platform support: windows is supported now.
2. The url mapping engine changed: from hard code to pattern based rules.
3. Rewrittens: API re-designed, logger added, code base re-structured.

## Lua pattern based rules

[Lua pattern](https://www.lua.org/pil/20.2.html) is introduced to map git remote
url to host url. The lua pattern has many limitations compared with the [standard regex expression](https://en.wikipedia.org/wiki/Regular_expression),
but it's still the best solution in git sharable file permalinks scenario.

For now github.com(include both git/http protocols and github enterprise) are supported:

- `git@github\.([_.+-\w]+):([.-\w]+)/([.-\w]+)(\.git)?` => `https://github.$1/$2/$3/blob/`
- `https?://github\.([_.+-\w]+):([.-\w]+)/([.-\w]+)(\.git)?` => `https://github.$1/$2/$3/blob/`

Notice above two rules are written with standard regex expressions, please see
[Configuration](#configuration) for all embeded pattern rules.

PRs are welcomed for other git host websites!

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

- `<leader>gl` (normal/visual mode): Open in browser and print message in command line.

To disable the default key mappings, set `mapping = false` in the `setup()`
function(see [Configuration](#configuration)).

To create key mappings, please use API `require"gitlinker".link(option)`.
The `option` is a table of options that override the configured options(see [Configuration](#configuration)).

For example:

```lua
vim.keymap.set({ 'n', 'x' }, '<leader>gb',
  '<cmd>lua require"gitlinker".link({action = require"gitlinker.actions".clipboard})<cr>',
  { desc = "Copy git link to clipboard" })
```

### Actions

- `require"gitlinker.actions".system`: Open git link in browser(the default action).
- `require"gitlinker.actions".clipboard`: Copy git link to clipboard.

## Configuration

Configure options in `setup()` function, they will override the defaults:

```lua
require('gitlinker').setup({
  -- system/clipboard
  action = require("gitlinker.actions").system,

  -- print message in command line
  message = true,

  -- key mapping
  mapping = "<leader>gl",

  -- regex pattern based rules
  pattern_rules = {
    {
      ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
      ["^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
    },
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

Notice the option `custom_rules` is either `nil` or a function with signature
`(string) => string`, the argument is git remote url, the return is git host url.
You can use this function to get the fully capabilities of url mapping.

## Contribute

### Code format

Please use [stylua](https://github.com/JohnnyMorganz/StyLua) for code formatting.

### Test pattern rules

Please test pattern rules before submit a PR:

- [lua/gitlinker/test/test_patterns.lua](https://github.com/linrongbin16/gitlinker.nvim/blob/e73201d76686dc4e9fc160a0f20fe40fcbccd5a9/lua/gitlinker/test/test_patterns.lua#L1)
- [lua/gitlinker/test/test_rules.lua](https://github.com/linrongbin16/gitlinker.nvim/blob/e73201d76686dc4e9fc160a0f20fe40fcbccd5a9/lua/gitlinker/test/test_rules.lua#L1)
