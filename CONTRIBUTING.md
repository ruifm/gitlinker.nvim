# Contributing to `gitlinker.nvim`

## Requirements

- [luacheck](https://github.com/luarocks/luacheck#installation) for linting
- [stylua](https://github.com/JohnnyMorganz/StyLua) for lua auto-formatting

## Lint

Pull requests have a CI check for linting issues. To run the linter locally:

``` bash
make lint
```

## Formatting

Lua formatting rules are specified in the `stylua.toml` file at the root of the
repository.

To auto-format all files:

``` bash
make format
```

## Support a new host

- Check how the url permalinks for that host are constructed.
- Create a new host callback in
  [lua/gitlinker/hosts.lua](./lua/gitlinker/hosts.lua) and add it to the
  `M.callbacks` table in that file.

## Add a new action callback

Create a new callback in
[lua/gitlinker/actions.lua](./lua/gitlinker/actions.lua)

## TODO

- Autogenerate docs
- Tests
