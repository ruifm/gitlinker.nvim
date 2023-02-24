# gitlinker.nvim

> A fork of [ruifm's gitlinker.nvim](https://github.com/ruifm/gitlinker.nvim) with bug fix, enhancements and refactor.

A lua [neovim](https://github.com/neovim/neovim) plugin to generate shareable
file permalinks (with line ranges) for several git web frontend hosts. Inspired
by [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)'s `:GBrowse`

Example of a permalink:
<https://github.com/neovim/neovim/blob/2e156a3b7d7e25e56b03683cc6228c531f4c91ef/src/nvim/main.c#L137-L156>

Personally, I use this all the time to easily share code locations with my
co-workers.

## Supported git web hosts

- [github](https://github.com)
- [gitlab](https://gitlab.com)
- [gitea](https://try.gitea.io)
- [bitbucket](https://bitbucket.org)
- [gogs](https://gogs.io)
- [cgit](https://git.zx2c4.com/cgit) (includes
  [git.kernel.org](https://git.kernel.org) and
  [git.savannah.gnu.org](http://git.savannah.gnu.org))
- [launchpad](https://launchpad.net)
- [repo.or.cz](https://repo.or.cz)

**You can easily configure support for more hosts** by defining your own host
callbacks. It's even easier if your host is just an enterprise/self-hosted
github/gitlab/gitea/gogs/cgit instance since you can just use the same callbacks
that already exist in gitlinker! See [callbacks](#callbacks).

### Requirements

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

> In this section, vim mode is specified with:
>
> - `"n"`: normal mode.
> - `"x"`: visual mode.
> - `"v"`: both visual and select mode.
>
> Please check:
>
> - <https://vi.stackexchange.com/q/4891/6600>
> - <https://vi.stackexchange.com/q/24895/6600>

### Defaults

By default, the following key mapping is defined to open git link in browser:

- `<leader>gl` (normal mode): Open in browser and print in command line. It will add the current line to url.
- `<leader>gl` (visual/select mode): Open in browser and print command line. It will add the range of selected lines to url.

To disable the default key mapping, set `mappings = false` or `mappings = ''` in the `setup()` function (see [Configuration](#configuration)).

### Api

If you want to disable mappings and set them on your own, the function you are
looking for is `require"gitlinker".get_buf_range_url(mode, user_opts)` where:

- `mode` is the either `"n"` (normal) or `"v"` (visual/select).

- `user_opts` is a table of options that override the ones set in `setup()` (see
  [Configuration](#configuration)). Because it just overrides, you do not need
  to pass this parameter, only if you want to change something.

  Example for setting extra mappings for an alternative `action_callback` (in
  this case, open in browser):

  ```lua
  vim.api.nvim_set_keymap('n', '<leader>gb', '<cmd>lua require"gitlinker".get_buf_range_url("n", {action_callback = require"gitlinker.actions".open_in_browser})<cr>', {silent = true})
  vim.api.nvim_set_keymap('v', '<leader>gb', '<cmd>lua require"gitlinker".get_buf_range_url("v", {action_callback = require"gitlinker.actions".open_in_browser})<cr>', {})
  ```

### Repo home page url

For convenience, the function
`require"gitlinker".get_buf_range_url(mode, user_opts)` allows one to generate
the url for the repository homepage. You can map it like so:

```lua
vim.api.nvim_set_keymap('n', '<leader>gY', '<cmd>lua require"gitlinker".get_repo_url()<cr>', {silent = true})
vim.api.nvim_set_keymap('n', '<leader>gB', '<cmd>lua require"gitlinker".get_repo_url({action_callback = require"gitlinker.actions".open_in_browser})<cr>', {silent = true})
```

And use `<leader>gY` to copy the repo's homepage to your clipboard or
`<leader>gB` to open it in your browser.

## Configuration

To customize configs, speicify options in `setup()` function:

```lua
require('gitlinker').setup({
  -- Force the use of a specific remote
  -- By default nil, handled by plugin itself.
  remote = nil,

  -- By default open git link in browser.
  action_callback = require("gitlinker.actions").open_in_browser,

  -- Print the url after action.
  print_url = true,

  -- key mappings
  mappings = "<leader>gl",

  -- Remote url translate rules.
  callbacks = {
    ["github.com"] = M.get_github_type_url,
    ["gitlab.com"] = M.get_gitlab_type_url,
    ["try.gitea.io"] = M.get_gitea_type_url,
    ["codeberg.org"] = M.get_gitea_type_url,
    ["bitbucket.org"] = M.get_bitbucket_type_url,
    ["try.gogs.io"] = M.get_gogs_type_url,
    ["git.sr.ht"] = M.get_srht_type_url,
    ["git.launchpad.net"] = M.get_launchpad_type_url,
    ["repo.or.cz"] = M.get_repoorcz_type_url,
    ["git.kernel.org"] = M.get_cgit_type_url,
    ["git.savannah.gnu.org"] = M.get_cgit_type_url,
  },

  -- Enable debug
  debug = false,
})
```

User options can override the default options, while the `nil` fields will stay with default value.

### callbacks

Besides the already configured hosts in the `callbacks` table, one can add
support for other git web hosts or self-hosted and enterprise instances.

In the key, place a string with the hostname and in value a callback function
that constructs the url and receives:

```lua
url_data = {
  host = "<host.tld>",
  port = "3000" or nil,
  repo = "<user/repo>",
  rev = "<commit sha>",
  file = "<path/to/file/from/repo/root>",
  lstart = 42, -- the line start of the selected range / current line
  lend = 57, -- the line end of the selected range
}
```

`port` will always be `nil` except when the remote URI configured locally is
http(s) **and specifies a port** (e.g. `http://localhost:3000/user/repo.git`),
in which case the generated url permalink also needs the right port.

As an example, here is the callback for github (**you don't need this, it's
already builtin**, it's just an example):

```lua
callbacks = {
  ["github.com"] = function(url_data)
      local url = require"gitlinker.hosts".get_base_https_url(url_data) ..
        url_data.repo .. "/blob/" .. url_data.rev .. "/" .. url_data.file
      if url_data.lstart then
        url = url .. "#L" .. url_data.lstart
        if url_data.lend then url = url .. "-L" .. url_data.lend end
      end
      return url
    end
}
```

If you want to add support for your company's gitlab instance:

```lua
callbacks = {
  ["git.seriouscompany.com"] = require"gitlinker.hosts".get_gitlab_type_url
}
```

Here is my personal configuration for my personal self-hosted gitea instance for
which the `host` is a local one (since I can only access it from my LAN) and but
the web interface is public:

```lua
callbacks = {
  ["192.168.1.2"] = function(url_data)
      url_data.host = "git.ruimarques.xyz"
      return
          require"gitlinker.hosts".get_gitea_type_url(url_data)
    end
}
```

**Warning**: The keys in `callbacks` table are actually interpreted as lua
regexes. If your url contains magic lua character such as `-`, it needs to be
escaped as `%-`.

### Options

- `remote`

If `remote = nil` (default), the relevant remote will be auto-detected. If you
have multiple git remotes configured and want to use a specific one
(e.g. `myfork`), do `remote = "myfork"`.

- `action_callback`

A function that receives a url string and decides which action to take. By
default set to `require"gitlinker.actions".copy_to_clipboard` which copies to
generated url to your system clipboard.

An alternative callback `require"gitlinker.actions".open_in_browser` is provided
which opens the url in your preferred browser using `xdg-open` (linux only).

You can define your own action call
