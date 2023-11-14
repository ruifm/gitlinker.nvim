local logger = require("gitlinker.logger")
local Linker = require("gitlinker.linker").Linker
local highlight = require("gitlinker.highlight")

--- @alias Options table<any, any>
--- @type Options
local Defaults = {
  -- print permanent url in command line
  --
  --- @type boolean
  message = true,

  -- highlight the linked region
  --
  --- @type integer
  highlight_duration = 500,

  -- add '?plain=1' for '*.md' (markdown) files
  --
  --- @type boolean
  add_plain_for_markdown = true,

  -- key mappings
  --
  --- @alias KeyMappingConfig {action:fun(url:string):nil,desc:string?}
  --- @type table<string, KeyMappingConfig>
  mapping = {
    ["<leader>gl"] = {
      action = require("gitlinker.actions").clipboard,
      desc = "Copy git link to clipboard",
    },
    ["<leader>gL"] = {
      action = require("gitlinker.actions").system,
      desc = "Open git link in browser",
    },
  },

  -- pattern based rules, mapping url from 'host' to 'remote'.
  --
  --- @type table<{[1]:string,[2]:string}>[]
  pattern_rules = {
    -- 'git@github' with '.git' suffix
    {
      "^git@github%.([_%.%-%w]+):([%.%-%w]+)/([_%.%-%w]+)%.git$",
      "https://github.%1/%2/%3/blob/",
    },
    -- 'git@github' without '.git' suffix
    {
      "^git@github%.([_%.%-%w]+):([%.%-%w]+)/([_%.%-%w]+)$",
      "https://github.%1/%2/%3/blob/",
    },
    -- 'http(s)?://github' with '.git' suffix
    {
      "^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([_%.%-%w]+)%.git$",
      "https://github.%1/%2/%3/blob/",
    },
    -- 'http(s)?://github' without '.git' suffix
    {
      "^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([_%.%-%w]+)$",
      "https://github.%1/%2/%3/blob/",
    },
    -- 'git@gitlab' with '.git' suffix
    {
      "^git@gitlab%.([_%.%-%w]+):([%.%-%w]+)/([_%.%-%w]+)%.git$",
      "https://gitlab.%1/%2/%3/blob/",
    },
    -- 'git@gitlab' without '.git' suffix
    {
      "^git@gitlab%.([_%.%-%w]+):([%.%-%w]+)/([_%.%-%w]+)$",
      "https://gitlab.%1/%2/%3/blob/",
    },
    -- 'http(s)?://gitlab' with '.git' suffix
    {
      "^https?://gitlab%.([_%.%-%w]+)/([%.%-%w]+)/([_%.%-%w]+)%.git$",
      "https://gitlab.%1/%2/%3/blob/",
    },
    -- 'http(s)?://gitlab' without '.git' suffix
    {
      "^https?://gitlab%.([_%.%-%w]+)/([%.%-%w]+)/([_%.%-%w]+)$",
      "https://gitlab.%1/%2/%3/blob/",
    },
  },

  -- override 'pattern_rules' with your own rules here.
  --
  -- **note**:
  --
  -- if you directly add your own rules in 'pattern_rules', it will remove other rules.
  -- but 'override_rules' will only prepend your own rules before 'pattern_rules', e.g. override.
  override_rules = nil,

  -- function based rules to override the default pattern_rules.
  -- function(remote_url) => host_url
  --
  -- here's an example:
  --
  -- ```
  -- custom_rules = function(remote_url)
  --     local rules = {
  --         -- 'git@github' end with '.git' suffix
  --         {
  --             "^git@github%.([_%.%-%w]+):([%.%-%w]+)/([_%.%-%w]+)%.git$",
  --             "https://github.%1/%2/%3/blob/",
  --         },
  --         -- 'git@github' end without '.git' suffix
  --         {
  --             "^git@github%.([_%.%-%w]+):([%.%-%w]+)/([_%.%-%w]+)$",
  --             "https://github.%1/%2/%3/blob/",
  --         },
  --     }
  --     for _, rule in ipairs(rules) do
  --         local pattern = rule[1]
  --         local replace = rule[2]
  --         if string.match(remote_url, pattern) then
  --             local result = string.gsub(remote_url, pattern, replace)
  --             return result
  --         end
  --     end
  --     return nil
  -- end,
  -- ```
  --
  --- @type fun(remote_url:string):string?|nil
  custom_rules = nil,

  -- enable debug
  --
  --- @type boolean
  debug = false,

  -- write logs to console(command line)
  --
  --- @type boolean
  console_log = true,

  -- write logs to file
  --
  --- @type boolean
  file_log = false,
}

--- @type Options
local Configs = {}

--- @param opts Options?
local function setup(opts)
  Configs = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), opts or {})

  -- logger
  logger.setup({
    level = Configs.debug and "DEBUG" or "INFO",
    console_log = Configs.console_log,
    file_log = Configs.file_log,
  })

  local key_mappings = nil
  if type(opts) == "table" and opts["mapping"] ~= nil then
    if type(opts["mapping"]) == "table" then
      key_mappings = opts["mapping"]
    end
  else
    key_mappings = Defaults.mapping
  end

  -- key mapping
  if type(key_mappings) == "table" then
    for k, v in pairs(key_mappings) do
      local opt = {
        noremap = true,
        silent = true,
      }
      if v.desc then
        opt.desc = v.desc
      end
      vim.keymap.set({ "n", "v" }, k, function()
        require("gitlinker").link({ action = v.action })
      end, opt)
    end
  end

  -- Configure highlight group
  if Configs.highlight_duration > 0 then
    local hl_name = "NvimGitLinkerHighlightTextObject"
    if not highlight.hl_group_exists(hl_name) then
      vim.api.nvim_set_hl(0, hl_name, { link = "Search" })
    end
  end

  -- logger.debug("|setup| Configs:%s", vim.inspect(Configs))
end

--- @deprecated
--- @package
--- @param pattern_rules table[]
--- @param remote_url string
--- @return string?
local function _map_remote_to_host_deprecated(pattern_rules, remote_url)
  for i, group in ipairs(pattern_rules) do
    for pattern, replace in pairs(group) do
      -- logger.debug(
      --   "[map_remote_to_host] map group[%d], pattern:'%s', replace:'%s'",
      --   i,
      --   pattern,
      --   replace
      -- )
      if string.match(remote_url, pattern) then
        local host_url = string.gsub(remote_url, pattern, replace)
        -- logger.debug(
        --   "[map_remote_to_host] map group[%d] matched, pattern:'%s', replace:'%s', remote_url:'%s' => host_url:'%s'",
        --   i,
        --   pattern,
        --   replace,
        --   remote_url,
        --   host_url
        -- )
        return host_url
      end
    end
  end

  return nil
end

--- @param pattern_rules table
--- @return boolean
local function _has_deprecated_pattern_rules(pattern_rules)
  if type(pattern_rules) ~= "table" then
    return false
  end
  for _, group in ipairs(pattern_rules) do
    if type(group) ~= "table" then
      return false
    end
    for pattern, replace in pairs(group) do
      if
        type(pattern) == "string"
        and string.len(pattern) > 0
        and type(replace) == "string"
        and string.len(replace) > 0
      then
        return true
      end
    end
  end
  return false
end

--- @package
--- @param remote_url string
--- @return string?
local function _map_remote_to_host(remote_url)
  local custom_rules = Configs.custom_rules
  if type(custom_rules) == "function" then
    local result = custom_rules(remote_url)
    if result then
      return result
    end
  end

  local pattern_rules = Configs.pattern_rules
  if _has_deprecated_pattern_rules(pattern_rules) then
    local function notify()
      local function impl()
        local msg = string.format(
          "[gitlinker] warning! detect deprecated 'config.pattern_rules', please migrate to latest schema."
        )
        local chunks = { { msg, "WarningMsg" } }
        vim.api.nvim_echo(chunks, false, {})
      end

      vim.schedule(impl)
      vim.defer_fn(impl, 3000)
    end
    notify()

    logger.debug("|_map_remote_to_host| use deprecated pattern rules schema")
    local result = _map_remote_to_host_deprecated(pattern_rules, remote_url)
    if result then
      return result
    end
  end

  logger.debug("|_map_remote_to_host| use new pattern rules schema")
  pattern_rules = vim.list_extend(
    vim.deepcopy(Configs.override_rules or {}),
    vim.deepcopy(pattern_rules)
  )
  for i, rule in ipairs(pattern_rules) do
    local pattern = rule[1]
    local replace = rule[2]
    -- logger.debug(
    --   "[map_remote_to_host] map group[%d], pattern:'%s', replace:'%s'",
    --   i,
    --   pattern,
    --   replace
    -- )
    if string.match(remote_url, pattern) then
      local host_url = string.gsub(remote_url, pattern, replace)
      -- logger.debug(
      --   "[map_remote_to_host] map group[%d] matched, pattern:'%s', replace:'%s', remote_url:'%s' => host_url:'%s'",
      --   i,
      --   pattern,
      --   replace,
      --   remote_url,
      --   host_url
      -- )
      return host_url
    end
  end

  return nil
end

--- @param host_url string
--- @param lk Linker
--- @param opts Options?
--- @return string
local function _make_sharable_permalinks(host_url, lk, opts)
  local url = string.format([[%s%s/%s]], host_url, lk.rev, lk.file)

  local add_plain = type(opts) == "table"
    and type(opts.add_plain_for_markdown) == "boolean"
    and opts.add_plain_for_markdown
  local endswith_md = type(url) == "string"
    and string.len(url) >= 3
    and url:sub(#url - 2, #url):lower() == ".md"
  -- logger.debug(
  --     "|_make_sharable_permalinks| url:%s, add plain:%s, url sub:%s, lower:%s, endswith '*.md':%s",
  --     vim.inspect(url),
  --     vim.inspect(add_plain),
  --     vim.inspect(url:sub(#url - 2, #url)),
  --     vim.inspect(url:sub(#url - 2, #url):lower()),
  --     vim.inspect(url:sub(#url - 2, #url):lower() == ".md")
  -- )
  if add_plain and endswith_md then
    url = url .. [[?plain=1]]
  end

  if type(lk.lstart) == "number" then
    url = string.format([[%s#L%d]], url, lk.lstart)
    if type(lk.lend) == "number" and lk.lend > lk.lstart then
      url = string.format([[%s-L%d]], url, lk.lend)
    end
  end

  return url
end

--- @param opts Options?
--- @return string?
local function link(opts)
  opts = vim.tbl_deep_extend("force", vim.deepcopy(Configs), opts or {})
  logger.debug("[link] merged opts: %s", vim.inspect(opts))

  local range = (type(opts.lstart) == "number" and type(opts.lend) == "number")
      and { lstart = opts.lstart, lend = opts.lend }
    or nil
  local lk = Linker:make(range)
  if not lk then
    return nil
  end

  local host_url = _map_remote_to_host(lk.remote_url) --[[@as string]]
  logger.ensure(
    type(host_url) == "string" and string.len(host_url) > 0,
    "fatal: failed to generate permanent url from remote url:%s",
    lk.remote_url
  )

  local url = _make_sharable_permalinks(host_url, lk, opts)
  if opts.action then
    opts.action(url)
  end
  if opts.highlight_duration > 0 then
    highlight.show({ lstart = lk.lstart, lend = lk.lend })
    vim.defer_fn(highlight.clear, opts.highlight_duration)
  end
  if opts.message then
    local msg = lk.file_changed
        and string.format("%s (lines can be wrong due to file change)", url)
      or url
    logger.info(msg)
  end

  return url
end

local M = {
  setup = setup,
  link = link,
  _make_sharable_permalinks = _make_sharable_permalinks,
  _map_remote_to_host = _map_remote_to_host,
}

return M
