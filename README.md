<!-- markdownlint-disable MD013 MD034 -->

# gitlinker.nvim

<p align="center">
<a href="https://github.com/neovim/neovim/releases/v0.7.0"><img alt="Neovim" src="https://img.shields.io/badge/Neovim-v0.7-57A143?logo=neovim&logoColor=57A143" /></a>
<a href="https://github.com/linrongbin16/gitlinker.nvim/search?l=lua"><img alt="Language" src="https://img.shields.io/github/languages/top/linrongbin16/gitlinker.nvim?label=Lua&logo=lua&logoColor=fff&labelColor=2C2D72" /></a>
<a href="https://github.com/linrongbin16/gitlinker.nvim/actions/workflows/ci.yml"><img alt="ci.yml" src="https://img.shields.io/github/actions/workflow/status/linrongbin16/gitlinker.nvim/ci.yml?label=GitHub%20CI&labelColor=181717&logo=github&logoColor=fff" /></a>
<a href="https://app.codecov.io/github/linrongbin16/gitlinker.nvim"><img alt="codecov" src="https://img.shields.io/codecov/c/github/linrongbin16/gitlinker.nvim?logo=codecov&logoColor=F01F7A&label=Codecov" /></a>
</p>

> Maintained fork of [ruifm's gitlinker](https://github.com/ruifm/gitlinker.nvim), refactored with bug fixes, git alias host, `/blame` url support and other improvements.

A lua plugin for [Neovim](https://github.com/neovim/neovim) to generate sharable file permalinks (with line ranges) for git host websites. Inspired by [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)'s `:GBrowse`.

Here's an example of git permalink: https://github.com/neovim/neovim/blob/2e156a3b7d7e25e56b03683cc6228c531f4c91ef/src/nvim/main.c#L137-L156.

![gitlinker](https://github.com/linrongbin16/gitlinker.nvim/assets/6496887/0d83fd82-4726-4dae-a70d-2c07236981b6)

For now supported platforms are:

- [github.com](https://github.com/)
- [gitlab.com](https://gitlab.com/)
- [bitbucket.org](https://bitbucket.org/)

PRs are welcomed for other git host websites!

## Table of Contents

- [Break Changes & Updates](#break-changes--updates)
- [Installation](#installation)
  - [packer.nvim](#packernvim)
  - [vim-plug](#vim-plug)
  - [lazy.nvim](#lazynvim)
- [Usage](#usage)
  - [Actions](#actions)
  - [Routers](#routers)
  - [API](#api)
- [Configuration](#configuration)
  - [Key Mappings](#key-mappings)
  - [Vim Command](#vim-command)
  - [Highlighting](#highlighting)
  - [Blame](#blame)
  - [Self-Host Git Hosts](#self-host-git-hosts)
  - [Fully Customize Urls](#fully-customize-urls)
- [Highlight Group](#highlight-group)
- [Development](#development)
- [Contribute](#contribute)

## Break Changes & Updates

1. Bug fix:
   - Customize/disable default key mappings.
2. New Features:
   - Windows support.
   - Respect ssh config alias host.
   - Add `?plain=1` for markdown files.
   - Support `/blame` (by default is `/blob`).
3. Improvements:
   - Use stderr from git command as error message.
   - Performant child process IO via `uv.spawn`.
   - Drop off `plenary` dependency.

## Installation

Requirement:

- neovim &ge; v0.7.
- [git](https://git-scm.com/).
- [ssh](https://www.openssh.com/) (optional for resolve git alias host).

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
return require('packer').startup(function(use)
  use {
    'linrongbin16/gitlinker.nvim',
    config = function()
      require('gitlinker').setup()
    end,
  }
end)
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
call plug#begin()

Plug 'linrongbin16/gitlinker.nvim'

call plug#end()

lua require('gitlinker').setup()
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
require("lazy").setup({
  {
    'linrongbin16/gitlinker.nvim',
    config = function()
      require('gitlinker').setup()
    end,
  },
})
```

## Usage

You could use below lua code to copy/open git link:

- `require('gitlinker').link({ action = require('gitlinker.actions').clipboard })` to copy git link to clipboard.
- `require('gitlinker').link({ action = require('gitlinker.actions').system })` to open git link in browser.

These two operations are already defined in key mappings:

- `<leader>gl` (normal/visual mode): copy to clipboard.
- `<leader>gL` (normal/visual mode): open in browser.

### Actions

- `require('gitlinker.actions').clipboard`: copy git link to clipboard.
- `require('gitlinker.actions').system`: open git link in browser.

### Routers

- `require('gitlinker.routers').browse`: generate the `/blob` url, by default `link` API will use this router.
- `require('gitlinker.routers').blame`: generate the `/blame` url.

> Note:
>
> - `browse` could generate other urls for other git host websites, e.g., `/src` for bitbucket.org.
> - `blame` could generate other urls for other git host websites, e.g., `/annotate` for bitbucket.org.

### API

`require('gitlinker').link(option)`: the main API that generate the git permalink, the `option` is a lua table that has below fields:

```lua
{
  -- (mandatory) gitlinker actions
  action = ...,

  -- (optional) gitlinker routers
  router = ...,

  -- (optional) line range, please see in [Vim Command](#vim-command).
  lstart = ...,
  lend = ...,
}
```

## Configuration

```lua
require('gitlinker').setup({
  -- print message in command line
  message = true,

  -- highlights the linked line(s) by the time in ms
  -- disable highlight by setting a value equal or less than 0
  highlight_duration = 500,

  -- key mapping
  mapping = {
    -- copy git link to clipboard
    ["<leader>gl"] = {
      action = require("gitlinker.actions").clipboard,
      desc = "Copy git link to clipboard",
    },
    -- open git link in browser
    ["<leader>gL"] = {
      action = require("gitlinker.actions").system,
      desc = "Open git link in browser",
    },
  },

  -- router bindings
  router_binding = {
    browse = {
      ["^github%.com"] = require("gitlinker.routers").github_browse,
      ["^gitlab%.com"] = require("gitlinker.routers").gitlab_browse,
      ["^bitbucket%.org"] = require("gitlinker.routers").bitbucket_browse,
    },
    blame = {
      ["^github%.com"] = require("gitlinker.routers").github_blame,
      ["^gitlab%.com"] = require("gitlinker.routers").gitlab_blame,
      ["^bitbucket%.org"] = require("gitlinker.routers").bitbucket_blame,
    },
  },

  -- enable debug
  debug = false,

  -- write logs to console(command line)
  console_log = true,

  -- write logs to file
  file_log = false,
})
```

### Key Mappings

To disable default key mappings, set `mapping = false`.

To create your own key mappings, please customize the `mapping` option, it will overwrite default options.

### Vim Command

To create your own vim command, please use:

```vim
" vimscript
" copy to clipboard
command! -range GitLink lua require('gitlinker').link({ action = require('gitlinker.actions').clipboard, lstart = vim.api.nvim_buf_get_mark(0, '<')[1], lend = vim.api.nvim_buf_get_mark(0, '>')[1] })
" or open in browser
command! -range GitLink lua require('gitlinker').link({ action = require('gitlinker.actions').system, lstart = vim.api.nvim_buf_get_mark(0, '<')[1], lend = vim.api.nvim_buf_get_mark(0, '>')[1] })
```

```lua
-- lua
-- copy to clipboard
vim.api.nvim_create_user_command("GitLink", function()
  require("gitlinker").link({
    action = require("gitlinker.actions").clipboard,
    lstart = vim.api.nvim_buf_get_mark(0, '<')[1],
    lend = vim.api.nvim_buf_get_mark(0, '>')[1]
  })
  end, {
  range = true,
})
-- or open in browser
vim.api.nvim_create_user_command("GitLink", function()
  require("gitlinker").link({
    action = require("gitlinker.actions").system,
    lstart = vim.api.nvim_buf_get_mark(0, '<')[1],
    lend = vim.api.nvim_buf_get_mark(0, '>')[1]
  })
  end, {
  range = true,
})
```

> Support command range is a little bit tricky, since you need to pass line range from command line to the `link` API.
>
> Todo: add the `GitLink` command.

### Highlighting

To create your own highlighting, please use:

```lua
-- lua
vim.api.nvim_set_hl( 0, "NvimGitLinkerHighlightTextObject", { link = "Constant" })
```

```vim
" vimscript
hi link NvimGitLinkerHighlightTextObject Constant
```

> Also see [Highlight Group](#highlight-group).

### Blame

To generate `/blame` url, please specify the `router` option in `link` API:

- `require('gitlinker').link({ action = require('gitlinker.actions').clipboard, router = require('gitlinker.routers').blame })`: copy to clipboard.
- `require('gitlinker').link({ action = require('gitlinker.actions').system, router = require('gitlinker.routers').blame })`: open in browser.

Or just add new key mappings in `setup`:

```lua
require('gitlinker').setup({
  mapping = {
    -- don't remove the default keys or they will not been mapped.
    ["<leader>gl"] = {
      action = require("gitlinker.actions").clipboard,
      desc = "Copy git link to clipboard",
    },
    ["<leader>gL"] = {
      action = require("gitlinker.actions").system,
      desc = "Open git link in browser",
    },
    -- add new keys for `/blame`
    ["<leader>gb"] = {
      action = require("gitlinker.actions").clipboard,
      router = require("gitlinker.routers").blame, -- specify router
      desc = "Copy git link to clipboard",
    },
    ["<leader>gB"] = {
      action = require("gitlinker.actions").system,
      router = require("gitlinker.routers").blame, -- specify router
      desc = "Open git link in browser",
    },
  },
})
```

### Self-Host Git Hosts

To generate url for self-host git host websites, please specify bindings in `router_binding` option.

Below example shows how to apply the github style routers to a self-host github websites, e.g. `github.your.host`:

```lua
require('gitlinker').setup({
  router_binding = {
    browse = {
      -- add your host here
      ["^github%.your%.host"] = require('gitlinker.routers').github_browse,
    },
    blame = {
      -- add your host here
      ["^github%.your%.host"] = require('gitlinker.routers').github_blame,
    },
  },
})
```

> Note: the [lua pattern](https://www.lua.org/pil/20.2.html) needs to escape the `.` to `%.`.

### Fully Customize Urls

To fully customize url generation, please refer to the implementation of [routers.lua](https://github.com/linrongbin16/gitlinker.nvim/blob/master/lua/gitlinker/routers.lua), a router is simply construct the string from below components:

- Protocol: `git`, `https`, etc.
- Host: `github.com`, `gitlab.com`, `bitbucket.org`, etc.
- User: `linrongbin16` (for this plugin), `neovim` (for [neovim](https://github.com/neovim/neovim)), etc.
- Repo: `gitlinker.nvim`, `neovim`, etc.
- Rev: git commit, e.g. `dbf3922382576391fbe50b36c55066c1768b08b6`.
- File name: file path, e.g. `lua/gitlinker/routers.lua`.
- Line range: start/end line numbers, e.g. `#L37-L156`.

For example you can customize the line numbers in form `&line=1&lines-count=2` like this:

```lua
-- @param range {lstart:integer,lend:integer}
local function your_lines(range)
  if type(range) ~= 'table' or type(range.lstart) ~= 'number' then
    return nil
  end
  local tmp = string.format([[&lines=%d]], range.lstart)
  if type(range.lend) == "number" and range.lend > range.lstart then
    tmp = tmp .. string.format([[&lines-count=%d]], r.lend)
  end
  return tmp
end

require('gitlinker').setup({
  mapping = {
    ["<leader>gl"] = {
      action = require("gitlinker.actions").clipboard,
      desc = "Copy git link to clipboard",
      router = function(lk)
        local builder = require('gitlinker.routers').Builder:new(lk, your_lines)
        return builder:build("blob")
      end,
    },
  },
})
```

> Note: the `Builder` is an internal string helper class, there's no guarantee the internal class/function signature is stable.

## Highlight Group

| Highlight Group                  | Default Group | Description                          |
| -------------------------------- | ------------- | ------------------------------------ |
| NvimGitLinkerHighlightTextObject | Search        | highlight line ranges when copy/open |

## Development

To develop the project and make PR, please setup with:

- [lua_ls](https://github.com/LuaLS/lua-language-server).
- [stylua](https://github.com/JohnnyMorganz/StyLua).
- [luarocks](https://luarocks.org/).
- [luacheck](https://github.com/mpeterv/luacheck).

To run unit tests, please install below dependencies:

- [vusted](https://github.com/notomo/vusted).

Then test with `vusted ./test`.

## Contribute

Please also open [issue](https://github.com/linrongbin16/gitlinker.nvim/issues)/[PR](https://github.com/linrongbin16/gitlinker.nvim/pulls) for anything about gitlinker.nvim.

Like gitlinker.nvim? Consider

[![Github Sponsor](https://img.shields.io/badge/-Sponsor%20Me%20on%20Github-magenta?logo=github&logoColor=white)](https://github.com/sponsors/linrongbin16)
[![Wechat Pay](https://img.shields.io/badge/-Tip%20Me%20on%20WeChat-brightgreen?logo=wechat&logoColor=white)](https://linrongbin16.github.io/sponsor)
[![Alipay](https://img.shields.io/badge/-Tip%20Me%20on%20Alipay-blue?logo=alipay&logoColor=white)](https://linrongbin16.github.io/sponsor)
