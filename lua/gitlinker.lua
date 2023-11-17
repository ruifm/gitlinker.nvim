local logger = require("gitlinker.logger")
local linker = require("gitlinker.linker")
local highlight = require("gitlinker.highlight")
local deprecation = require("gitlinker.deprecation")
local utils = require("gitlinker.utils")

--- @alias gitlinker.Options table<any, any>
--- @type gitlinker.Options
local Defaults = {
  -- print permanent url in command line
  message = true,

  -- highlight the linked region
  highlight_duration = 500,

  -- user command
  command = {
    -- to copy link to clipboard, use: 'GitLink'
    -- to open link in browser, use bang: 'GitLink!'
    -- to use blame router, use: 'GitLink blame'
    -- to use browse router, use: 'GitLink browse' (which is the default router)
    name = "GitLink",
    desc = "Generate git permanent link",
  },

  -- router bindings
  router = {
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
}

--- @type gitlinker.Options
local Configs = {}

--- @param opts gitlinker.Options
local function deprecated_notification(opts)
  if type(opts) == "table" and opts.pattern_rules ~= nil then
    deprecation.notify(
      "'pattern_rules' option is deprecated! please migrate to latest configs."
    )
  end
  if type(opts) == "table" and opts.override_rules ~= nil then
    deprecation.notify(
      "'override_rules' option is deprecated! please migrate to latest configs."
    )
  end
  if type(opts) == "table" and opts.custom_rules ~= nil then
    deprecation.notify(
      "'custom_rules' option is deprecated! please migrate to latest configs."
    )
  end
end

--- @param opts {action:gitlinker.Action,router:gitlinker.Router?}
--- @return string?
local function link(opts)
  -- logger.debug("[link] merged opts: %s", vim.inspect(opts))

  local lk = linker.make_linker()
  if not lk then
    return nil
  end

  local router = opts.router or require("gitlinker.routers").browse
  if not router then
    return nil
  end

  local ok, url = pcall(router, lk, true)
  logger.debug(
    "|link| ok:%s, url:%s, router:%s",
    vim.inspect(ok),
    vim.inspect(url),
    vim.inspect(router)
  )
  logger.ensure(
    ok and type(url) == "string" and string.len(url) > 0,
    "fatal: failed to generate permanent url from remote url (%s): %s",
    vim.inspect(lk.remote_url),
    vim.inspect(url)
  )

  if opts.action then
    opts.action(url --[[@as string]])
  end

  if Configs.highlight_duration > 0 then
    highlight.show({ lstart = lk.lstart, lend = lk.lend })
    vim.defer_fn(highlight.clear, Configs.highlight_duration)
  end

  if Configs.message then
    local msg = lk.file_changed
        and string.format("%s (lines can be wrong due to file change)", url)
      or url
    logger.info(msg)
  end

  return url
end

--- @param opts gitlinker.Options?
--- @return gitlinker.Options
local function _merge_routers(opts)
  -- browse
  local browse_routers = vim.deepcopy(Defaults.router.browse)
  local browse_router_binding_opts = {}
  if
    type(opts) == "table"
    and type(opts.router_binding) == "table"
    and type(opts.router_binding.browse) == "table"
  then
    deprecation.notify(
      "'router_binding' is renamed to 'router', please update to latest configs!"
    )
    browse_router_binding_opts = vim.deepcopy(opts.router_binding.browse)
  end
  local browse_router_opts = (
    type(opts) == "table"
    and type(opts.router) == "table"
    and type(opts.router.browse) == "table"
  )
      and vim.deepcopy(opts.router.browse)
    or {}
  browse_routers = vim.tbl_extend(
    "force",
    vim.deepcopy(browse_routers),
    browse_router_binding_opts
  )
  browse_routers =
    vim.tbl_extend("force", vim.deepcopy(browse_routers), browse_router_opts)

  -- blame
  local blame_routers = vim.deepcopy(Defaults.router.blame)
  local blame_router_binding_opts = {}
  if
    type(opts) == "table"
    and type(opts.router_binding) == "table"
    and type(opts.router_binding.blame) == "table"
  then
    deprecation.notify(
      "'router_binding' is renamed to 'router', please update to latest configs!"
    )
    blame_router_binding_opts = vim.deepcopy(opts.router_binding.blame)
  end
  local blame_router_opts = (
    type(opts) == "table"
    and type(opts.router) == "table"
    and type(opts.router.blame) == "table"
  )
      and vim.deepcopy(opts.router.blame)
    or {}
  blame_routers = vim.tbl_extend(
    "force",
    vim.deepcopy(blame_routers),
    blame_router_binding_opts
  )
  blame_routers =
    vim.tbl_extend("force", vim.deepcopy(blame_routers), blame_router_opts)

  return {
    browse = browse_routers,
    blame = blame_routers,
  }
end

--- @param opts gitlinker.Options?
local function setup(opts)
  local router_configs = _merge_routers(opts)
  Configs = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), opts or {})
  Configs.router = router_configs

  -- logger
  logger.setup({
    level = Configs.debug and "DEBUG" or "INFO",
    console_log = Configs.console_log,
    file_log = Configs.file_log,
  })

  -- router binding
  require("gitlinker.routers").setup(Configs.router or {})

  -- command
  vim.api.nvim_create_user_command(Configs.command.name, function(command_opts)
    local parsed_args = (
      type(command_opts.args) == "string"
      and string.len(command_opts.args) > 0
    )
        and vim.trim(command_opts.args)
      or nil
    logger.debug(
      "command opts:%s, parsed:%s",
      vim.inspect(command_opts),
      vim.inspect(parsed_args)
    )
    local router = require("gitlinker.routers").browse
    if parsed_args == "blame" then
      router = require("gitlinker.routers").blame
    end
    local action = require("gitlinker.actions").clipboard
    if command_opts.bang then
      action = require("gitlinker.actions").system
    end
    link({ action = action, router = router })
  end, {
    nargs = "*",
    range = true,
    bang = true,
    desc = Configs.command.desc,
  })

  if type(Configs.mapping) == "table" then
    deprecation.notify(
      "'mapping' option is deprecated! please migrate to 'GitLink' command."
    )
  end

  -- Configure highlight group
  if Configs.highlight_duration > 0 then
    local hl_group = "NvimGitLinkerHighlightTextObject"
    if not highlight.hl_group_exists(hl_group) then
      vim.api.nvim_set_hl(0, hl_group, { link = "Search" })
    end
  end

  -- logger.debug("|setup| Configs:%s", vim.inspect(Configs))

  deprecated_notification(Configs)
end

local M = {
  setup = setup,
  link = link,
}

return M
