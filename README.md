# gitlinker.nvim

> A fork of [ruifm's gitlinker.nvim](https://github.com/ruifm/gitlinker.nvim) with
> bug fix, enhancements and refactor.

A lua plugin for [Neovim](https://github.com/neovim/neovim) to generate shareable
file permalinks (with line ranges) for git host websites. Inspired by
[tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)'s `:GBrowse`.

Example of a permalink:
<https://github.com/neovim/neovim/blob/2e156a3b7d7e25e56b03683cc6228c531f4c91ef/src/nvim/main.c#L137-L156>

Personally, I use this all the time to easily share code locations with my
co-workers.

## Regex Pattern based Rules

- `git@github.{host-suffix}/{organization}/{repository}(.git)?` => `https://github.{host-suffix}/{organization}/{repository}/blob/`
- `https://github.{host-suffix}/{organization}/{repository}(.git)?` => `https://github.{host-suffix}/{organization}/{repository}/blob/`

Regex pattern based rules are introduced for mapping from local git remote to the
git host website url. For now github.com (include git and http protocol, and
enterprise) are supported.

Please checkout [opts.lua](https://github.com/linrongbin16/gitlinker.nvim/blob/master/lua/gitlinker/opts.lua)
to find out the regex patterns, or submit PR for other git hosts!

## Requirement

- git
- neovim 0.8
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'ruifm/gitlinker.nvim',
    requires = 'nvim-lua/plenary.nvim',
    branch = 'main',
    config = function()
        require('gitlinker').setup()
    end,
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'ruifm/gitlinker.nvim', { 'branch': 'master' }
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

### Default

By default, the following key mapping is defined to open git link in browser:

- `<leader>gl` (normal mode): Open in browser and print url in command line.
- `<leader>gl` (visual mode): Open in browser and print url in command line.

To disable the default key mapping, set `mappings = false` or `mappings = ''` in
the `setup()` function(see [Configuration](#configuration)).

### Key Mapping

If you want custom key mappings, please use API `require"gitlinker".get_buf_range_url(user_opts)`.
The `user_opts` is a table of options that override the default options(see [Configuration](#configuration)).

```lua
vim.api.nvim_set_keymap('n', '<leader>gb',
  '<cmd>lua require"gitlinker".get_buf_range_url({action_callback = require"gitlinker.actions".open_in_browser})<cr>',
  { desc = "Open git link in browser" })
vim.api.nvim_set_keymap('x', '<leader>gb',
  '<cmd>lua require"gitlinker".get_buf_range_url({action_callback = require"gitlinker.actions".open_in_browser})<cr>',
  { desc = "Open git link in browser" })
```

## Configuration

Speicify configs in `setup()` function, they will override the defaults(see
[default options](https://github.com/linrongbin16/gitlinker.nvim/blob/master/lua/gitlinker/opts.lua)).

You can also pass options to API `require"gitlinker".get_buf_range_url(user_opts)`,
they will override options(only in this API call).
