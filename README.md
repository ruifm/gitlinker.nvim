# gitlinker.nvim

> A fork of [ruifm's gitlinker](https://github.com/ruifm/gitlinker.nvim), refactored
> with pattern based rule engine, windows support and other enhancements.

A lua plugin for [Neovim](https://github.com/neovim/neovim) to generate sharable
file permalinks (with line ranges) for git host websites. Inspired by
[tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)'s `:GBrowse`.

An example of git permalink:
<https://github.com/neovim/neovim/blob/2e156a3b7d7e25e56b03683cc6228c531f4c91ef/src/nvim/main.c#L137-L156>

Personally, I use this all the time to easily share code locations with my
co-workers.

## Break changes & updates

1. Platform support: windows is supported.
2. Url mapping engine changed: pattern based rules instead of hard coding.
3. Rewrittens: API re-designed, logger added, code base re-structured.

## Lua pattern based rules

[Lua pattern](https://www.lua.org/pil/20.2.html) is introduced to map git remote
url to host url. The lua pattern has many limitations compared with the
[standard regex expression](https://en.wikipedia.org/wiki/Regular_expression),
but it's still the best solution in git sharable file permalinks scenario.

For now github.com(include both git/http protocols and github enterprise) are supported:

- `git@github\.([_.+-\w]+):([.-\w]+)/([.-\w]+)(\.git)?` => `https://github.$1/$2/$3/blob/`
- `https?://github\.([_.+-\w]+):([.-\w]+)/([.-\w]+)(\.git)?` => `https://github.$1/$2/$3/blob/`

> Notice above two rules are written with standard regex expressions, please see
> [Configuration](#configuration) for all embeded pattern rules.

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
    requires = { 'nvim-lua/plenary.nvim' },
    branch = 'master',
    config = function()
        require('gitlinker').setup()
    end,
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
call plug#begin()

Plug 'nvim-lua/plenary.nvim'
Plug 'linrongbin16/gitlinker.nvim', { 'branch': 'master' }

call plug#end()

lua<<EOF
require('gitlinker').setup()
EOF
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    'linrongbin16/gitlinker.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        require('gitlinker').setup()
    end,
},
```

## Usage

There're two key mappings defined by default:

- `<leader>gl` (normal/visual mode): copy git link to clipboard.
- `<leader>gL` (normal/visual mode): open git link in default browser.

To disable the default key mappings, set `mapping = false` in `setup()` function(see
[Configuration](#configuration)).

To create your own key mappings, please use API `require("gitlinker").link(option)`.
The `option` is a lua table:

```lua
{
    action = require("gitlinker.actions").clipboard, -- clipboard/system
    message = true, -- true/false
}
```

For example:

```lua
vim.keymap.set(
    { 'n', 'x' },
    '<leader>gb',
    '<cmd>lua require("gitlinker").link({action = require("gitlinker.actions").clipboard})<cr>',
    { desc = "Copy git link to clipboard" }
)
```

### Actions

- `require("gitlinker.actions").clipboard`: copy git link to clipboard.
- `require("gitlinker.actions").system`: open git link in default browser.

## Configuration

````lua
require('gitlinker').setup({
  -- print message in command line
  message = true,

  -- key mapping
  mapping = {
    ["<leader>gl"] = {
      action = require("gitlinker.actions").clipboard,
      desc = "Copy git link to clipboard",
    },
    ["<leader>gL"] = {
      action = require("gitlinker.actions").system,
      desc = "Open git link in default browser",
    },
  },

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

  -- function based rules: function(remote_url) => host_url.
  -- this function will override the `pattern_rules`.
  -- here's an example of custom_rules:
  --
  -- ```
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
  -- ```
  --
  --- @overload fun(remote_url:string):string|nil
  custom_rules = nil,


  -- enable debug
  debug = false,

  -- write logs to console(command line)
  console_log = true,

  -- write logs to file
  file_log = false,
})
````

## Contribute

### Code format

Use [stylua](https://github.com/JohnnyMorganz/StyLua) for code formatting.

### Test pattern rules

Run test cases in [lua/gitlinker/test](https://github.com/linrongbin16/gitlinker.nvim/tree/master/lua/gitlinker/test).
