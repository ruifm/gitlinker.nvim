local range = require("gitlinker.range")
local LogLevels = require("gitlinker.logger").LogLevels
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
      -- example: https://github.com/linrongbin16/gitlinker.nvim/blob/9679445c7a24783d27063cd65f525f02def5f128/lua/gitlinker.lua#L3-L4
      ["^github%.com"] = "https://github.com/"
        .. "{_A.USER}/"
        .. "{_A.REPO}/blob/"
        .. "{_A.REV}/"
        .. "{_A.FILE}"
        .. "{(string.len(_A.FILE) >= 3 and _A.FILE:sub(#_A.FILE-2) == '.md') and '?plain=1' or ''}" -- '?plain=1'
        .. "#L{_A.LSTART}"
        .. "{(_A.LEND > _A.LSTART and ('-L' .. _A.LEND) or '')}",
      -- example: https://gitlab.com/linrongbin16/gitlinker.nvim/blob/9679445c7a24783d27063cd65f525f02def5f128/lua/gitlinker.lua#L3-L4
      ["^gitlab%.com"] = "https://gitlab.com/"
        .. "{_A.USER}/"
        .. "{_A.REPO}/blob/"
        .. "{_A.REV}/"
        .. "{_A.FILE}"
        .. "#L{_A.LSTART}"
        .. "{(_A.LEND > _A.LSTART and ('-L' .. _A.LEND) or '')}",
      -- example: https://bitbucket.org/linrongbin16/gitlinker.nvim/src/9679445c7a24783d27063cd65f525f02def5f128/lua/gitlinker.lua#L3-L4
      ["^bitbucket%.org"] = "https://bitbucket.org/"
        .. "{_A.USER}/"
        .. "{_A.REPO}/src/"
        .. "{_A.REV}/"
        .. "{_A.FILE}"
        .. "#lines-{_A.LSTART}"
        .. "{(_A.LEND > _A.LSTART and (':' .. _A.LEND) or '')}",
      -- example: https://codeberg.org/linrongbin16/gitlinker.nvim/src/commit/a570f22ff833447ee0c58268b3bae4f7197a8ad8/LICENSE#L5-L6
      ["^codeberg%.org"] = "https://codeberg.org/"
        .. "{_A.USER}/"
        .. "{_A.REPO}/src/commit/"
        .. "{_A.REV}/"
        .. "{_A.FILE}"
        .. "{(string.len(_A.FILE) >= 3 and _A.FILE:sub(#_A.FILE-2) == '.md') and '?display=source' or ''}" -- '?display=source'
        .. "#L{_A.LSTART}"
        .. "{(_A.LEND > _A.LSTART and ('-L' .. _A.LEND) or '')}",
    },
    blame = {
      -- example: https://github.com/linrongbin16/gitlinker.nvim/blame/9679445c7a24783d27063cd65f525f02def5f128/lua/gitlinker.lua#L3-L4
      ["^github%.com"] = "https://github.com/"
        .. "{_A.USER}/"
        .. "{_A.REPO}/blame/"
        .. "{_A.REV}/"
        .. "{_A.FILE}"
        .. "{(string.len(_A.FILE) >= 3 and _A.FILE:sub(#_A.FILE-2) == '.md') and '?plain=1' or ''}"
        .. "#L{_A.LSTART}"
        .. "{(_A.LEND > _A.LSTART and ('-L' .. _A.LEND) or '')}",
      -- example: https://gitlab.com/linrongbin16/gitlinker.nvim/blame/9679445c7a24783d27063cd65f525f02def5f128/lua/gitlinker.lua#L3-L4
      ["^gitlab%.com"] = "https://gitlab.com/"
        .. "{_A.USER}/"
        .. "{_A.REPO}/blame/"
        .. "{_A.REV}/"
        .. "{_A.FILE}"
        .. "#L{_A.LSTART}"
        .. "{(_A.LEND > _A.LSTART and ('-L' .. _A.LEND) or '')}",
      -- example: https://bitbucket.org/linrongbin16/gitlinker.nvim/annotate/9679445c7a24783d27063cd65f525f02def5f128/lua/gitlinker.lua#L3-L4
      ["^bitbucket%.org"] = "https://bitbucket.org/"
        .. "{_A.USER}/"
        .. "{_A.REPO}/annotate/"
        .. "{_A.REV}/"
        .. "{_A.FILE}"
        .. "#lines-{_A.LSTART}"
        .. "{(_A.LEND > _A.LSTART and (':' .. _A.LEND) or '')}",
      -- example: https://codeberg.org/linrongbin16/gitlinker.nvim/blame/commit/a570f22ff833447ee0c58268b3bae4f7197a8ad8/LICENSE#L5-L6
      ["^codeberg%.org"] = "https://codeberg.org/"
        .. "{_A.USER}/"
        .. "{_A.REPO}/blame/commit/"
        .. "{_A.REV}/"
        .. "{_A.FILE}"
        .. "#L{_A.LSTART}"
        .. "{(_A.LEND > _A.LSTART and ('-L' .. _A.LEND) or '')}",
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

--- @param lk gitlinker.Linker
--- @param template string
--- @return string
local function _url_template_engine(lk, template)
  local OPEN_BRACE = "{"
  local CLOSE_BRACE = "}"
  if type(template) ~= "string" or string.len(template) == 0 then
    return template
  end

  --- @alias gitlinker.UrlTemplateExpr {plain:boolean,body:string}
  --- @type gitlinker.UrlTemplateExpr[]
  local exprs = {}

  local i = 1
  local n = string.len(template)
  while i <= n do
    local open_pos = utils.string_find(template, OPEN_BRACE, i)
    if not open_pos then
      table.insert(exprs, { plain = true, body = string.sub(template, i) })
      break
    end
    table.insert(
      exprs,
      { plain = true, body = string.sub(template, i, open_pos - 1) }
    )
    local close_pos = utils.string_find(
      template,
      CLOSE_BRACE,
      open_pos + string.len(OPEN_BRACE)
    )
    assert(
      type(close_pos) == "number" and close_pos > open_pos,
      string.format(
        "failed to evaluate url template(%s) at pos %d",
        vim.inspect(template),
        open_pos + string.len(OPEN_BRACE)
      )
    )
    table.insert(exprs, {
      plain = false,
      body = string.sub(
        template,
        open_pos + string.len(OPEN_BRACE),
        close_pos - 1
      ),
    })
    logger.debug(
      "|routers.url_template| expressions:%s (%d-%d)",
      vim.inspect(exprs),
      vim.inspect(open_pos),
      vim.inspect(close_pos)
    )
    i = close_pos + string.len(CLOSE_BRACE)
  end
  logger.debug(
    "|routers.url_template| final expressions:%s",
    vim.inspect(exprs)
  )

  local results = {}
  for _, exp in ipairs(exprs) do
    if exp.plain then
      table.insert(results, exp.body)
    else
      local evaluated = vim.fn.luaeval(exp.body, {
        PROTOCOL = lk.protocol,
        HOST = lk.host,
        USER = lk.user,
        REPO = utils.string_endswith(lk.repo, ".git")
            and lk.repo:sub(1, #lk.repo - 4)
          or lk.repo,
        REV = lk.rev,
        FILE = lk.file,
        LSTART = lk.lstart,
        LEND = (type(lk.lend) == "number" and lk.lend > lk.lstart) and lk.lend
          or lk.lstart,
      })
      logger.debug(
        "|_url_template_engine| exp:%s, lk:%s, evaluated:%s",
        vim.inspect(exp.body),
        vim.inspect(lk),
        vim.inspect(evaluated)
      )
      table.insert(results, evaluated)
    end
  end

  return table.concat(results, "")
end

--- @alias gitlinker.Router fun(lk:gitlinker.Linker):string
--- @param lk gitlinker.Linker
--- @return string?
local function _browse(lk)
  for pattern, route in pairs(Configs.router.browse) do
    if
      string.match(lk.host, pattern)
      or string.match(lk.protocol .. lk.host, pattern)
    then
      logger.debug(
        "|browse| match router:%s with pattern:%s",
        vim.inspect(route),
        vim.inspect(pattern)
      )
      if type(route) == "function" then
        return route(lk)
      elseif type(route) == "string" then
        return _url_template_engine(lk, route)
      else
        assert(
          false,
          string.format(
            "unsupported router %s on pattern %s",
            vim.inspect(route),
            vim.inspect(pattern)
          )
        )
      end
    end
  end
  assert(
    false,
    string.format(
      "%s not support, please bind it in 'router'!",
      vim.inspect(lk.host)
    )
  )
  return nil
end

--- @param lk gitlinker.Linker
--- @return string?
local function _blame(lk)
  for pattern, route in pairs(Configs.router.blame) do
    if
      string.match(lk.host, pattern)
      or string.match(lk.protocol .. lk.host, pattern)
    then
      logger.debug(
        "|blame| match router:%s with pattern:%s",
        vim.inspect(route),
        vim.inspect(pattern)
      )
      if type(route) == "function" then
        return route(lk)
      elseif type(route) == "string" then
        return _url_template_engine(lk, route)
      else
        assert(
          false,
          string.format(
            "unsupported router %s on pattern %s",
            vim.inspect(route),
            vim.inspect(pattern)
          )
        )
      end
    end
  end
  assert(
    false,
    string.format(
      "%s not support, please bind it in 'router'!",
      vim.inspect(lk.host)
    )
  )
  return nil
end

--- @param opts {action:gitlinker.Action,router:gitlinker.Router,lstart:integer,lend:integer}
--- @return string?
local function link(opts)
  -- logger.debug("[link] merged opts: %s", vim.inspect(opts))

  local lk = linker.make_linker()
  if not lk then
    return nil
  end
  lk.lstart = opts.lstart
  lk.lend = opts.lend

  local ok, url = pcall(opts.router, lk, true)
  logger.debug(
    "|link| ok:%s, url:%s, router:%s",
    vim.inspect(ok),
    vim.inspect(url),
    vim.inspect(opts.router)
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

--- @param opts gitlinker.Options
--- @return gitlinker.Options
local function _merge_routers(opts)
  -- browse
  local browse_routers = vim.deepcopy(Defaults.router.browse)
  local browse_router_binding_opts = {}
  if
    type(opts.router_binding) == "table"
    and type(opts.router_binding.browse) == "table"
  then
    deprecation.notify(
      "'router_binding' is renamed to 'router', please update to latest configs!"
    )
    browse_router_binding_opts = vim.deepcopy(opts.router_binding.browse)
  end
  local browse_router_opts = (
    type(opts.router) == "table" and type(opts.router.browse) == "table"
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
    type(opts.router_binding) == "table"
    and type(opts.router_binding.blame) == "table"
  then
    deprecation.notify(
      "'router_binding' is renamed to 'router', please update to latest configs!"
    )
    blame_router_binding_opts = vim.deepcopy(opts.router_binding.blame)
  end
  local blame_router_opts = (
    type(opts.router) == "table" and type(opts.router.blame) == "table"
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
  local router_configs = _merge_routers(opts or {})
  Configs = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), opts or {})
  Configs.router = router_configs

  -- logger
  logger.setup({
    level = Configs.debug and LogLevels.DEBUG or LogLevels.INFO,
    console_log = Configs.console_log,
    file_log = Configs.file_log,
  })

  -- command
  vim.api.nvim_create_user_command(Configs.command.name, function(command_opts)
    local r = range.make_range()
    local parsed_args = (
      type(command_opts.args) == "string"
      and string.len(command_opts.args) > 0
    )
        and vim.trim(command_opts.args)
      or nil
    logger.debug(
      "command opts:%s, parsed:%s, range:%s",
      vim.inspect(command_opts),
      vim.inspect(parsed_args),
      vim.inspect(r)
    )
    local lstart =
      math.min(r.lstart, r.lend, command_opts.line1, command_opts.line2)
    local lend =
      math.max(r.lstart, r.lend, command_opts.line1, command_opts.line2)
    local router = _browse
    if parsed_args == "blame" then
      router = _blame
    end
    local action = require("gitlinker.actions").clipboard
    if command_opts.bang then
      action = require("gitlinker.actions").system
    end
    link({ action = action, router = router, lstart = lstart, lend = lend })
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
  _browse = _browse,
  _blame = _blame,
}

return M
