local git = require("gitlinker.git")
local util = require("gitlinker.util")
local keys = require("gitlinker.keys")
local logger = require("gitlinker.logger")

--- @type table<string, any>
local Defaults = {
  -- print message(git host url) in command line
  --- @type boolean
  message = true,

  -- key mapping
  --- @type table<string, table<string, function|string>>
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
  --- @type table<string, string>[]
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

  -- function based rules, signature: function(remote_url):host_url
  --
  -- here's an example of custom_rules:
  -- ```
  -- custom_rules = function(remote_url)
  --   local rules = {
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
  --   for _, group in ipairs(rules) do
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
  --- @type boolean
  debug = false,

  -- write logs to console(command line)
  --- @type boolean
  console_log = true,

  -- write logs to file
  --- @type boolean
  file_log = false,
}

--- @type table<string, any>
local Configs = {}

--- @param option table<string, any>
--- @return nil
local function setup(option)
  Configs = vim.tbl_deep_extend("force", Defaults, option or {})
  logger.setup({
    level = Configs.debug and "DEBUG" or "INFO",
    console = Configs.console_log,
    file = Configs.file_log,
  })
  keys.setup(Configs.mapping)
  logger.debug("[setup] Configs: %s", vim.inspect(Configs))
end

--- @class Linker
--- @field remote_url string
--- @field rev string
--- @field file string
--- @field lstart integer
--- @field lend integer
--- @field file_changed boolean
local Linker = {}

--- @param remote_url string
--- @param rev string
--- @param file string
--- @param lstart integer
--- @param lend integer
--- @param file_changed boolean
--- @return Linker
local function new_linker(remote_url, rev, file, lstart, lend, file_changed)
  local linker = vim.tbl_extend("force", vim.deepcopy(Linker), {
    remote_url = remote_url,
    rev = rev,
    file = file,
    lstart = lstart,
    lend = lend,
    file_changed = file_changed,
  })
  return linker
end

local function make_link_data()
  local root = git.get_root()
  if not root then
    logger.error("Error! Not in a git repository")
    return nil
  end

  local remote = git.get_branch_remote()
  if not remote then
    return nil
  end

  local remote_url = git.get_remote_url(remote)
  if not remote_url then
    logger.error("Error! Failed to get remote url by remote '%s'", remote)
    return nil
  end

  local rev = git.get_closest_remote_compatible_rev(remote)
  if not rev then
    return nil
  end

  local buf_path_on_root = util.relative_path(root)
  logger.debug(
    "[make_link_data] buf_path_on_root: %s, git_root: %s",
    vim.inspect(buf_path_on_root),
    vim.inspect(root)
  )
  if not git.is_file_in_rev(buf_path_on_root, rev) then
    logger.error(
      "Error! '%s' does not exist in remote '%s'",
      buf_path_on_root,
      remote
    )
    return nil
  end

  --- @type string
  local buf_path_on_cwd = util.relative_path()
  --- @type LineRange
  local range = util.line_range()
  logger.debug(
    "[make_link_data] buf_path_on_cwd:%s, range:%s",
    vim.inspect(buf_path_on_cwd),
    vim.inspect(range)
  )

  return new_linker(
    remote_url,
    rev,
    buf_path_on_root,
    range.lstart,
    range.lend,
    git.has_file_changed(buf_path_on_cwd, rev)
  )
end

--- @param remote_url string
--- @return string|nil host_url
local function map_remote_to_host(remote_url)
  local custom_rules = Configs.custom_rules
  if type(custom_rules) == "function" then
    return custom_rules(remote_url)
  else
    local pattern_rules = Configs.pattern_rules
    for i, group in ipairs(pattern_rules) do
      for pattern, replace in pairs(group) do
        logger.debug(
          "[map_remote_to_host] map group[%d], pattern:'%s', replace:'%s'",
          i,
          pattern,
          replace
        )
        if string.match(remote_url, pattern) then
          local host_url = string.gsub(remote_url, pattern, replace)
          logger.debug(
            "[map_remote_to_host] map group[%d] matched, pattern:'%s', replace:'%s', remote_url:'%s' => host_url:'%s'",
            i,
            pattern,
            replace,
            remote_url,
            host_url
          )
          return host_url
        end
      end
    end
  end

  return nil
end

--- @param host_url string
--- @param linker Linker
--- @return string
local function make_sharable_permalinks(host_url, linker)
  local url = host_url .. linker.rev .. "/" .. linker.file
  if not linker.lstart then
    return url
  end
  url = url .. "#L" .. linker.lstart
  if linker.lend and linker.lend ~= linker.lstart then
    url = url .. "-L" .. linker.lend
  end
  return url
end

-- Get the url for the buffer with selected lines
--- @param option table<string, any>
--- @return string|nil
local function link(option)
  logger.debug("[make_link] before merge, option: %s", vim.inspect(option))
  option = vim.tbl_deep_extend("force", Configs, option or {})
  logger.debug("[make_link] after merge, option: %s", vim.inspect(option))

  local linker = make_link_data()
  if not linker then
    return nil
  end

  local host_url = map_remote_to_host(linker.remote_url)

  if type(host_url) ~= "string" or string.len(host_url) <= 0 then
    logger.error(
      "Error! Cannot generate git link from remote url:%s",
      linker.remote_url
    )
    return nil
  end

  local url = make_sharable_permalinks(host_url, linker)

  if option.action then
    option.action(url)
  end
  if option.message then
    local msg = linker.file_changed
        and string.format("%s (lines can be wrong due to file change)", url)
      or url
    logger.info(msg)
  end

  return url
end

--- @type table<string, function>
local M = {
  --- @overload fun(option:table<string, any>):nil
  setup = setup,
  --- @overload fun(option:table<string, any>):string|nil
  link = link,
  --- @overload fun(remote_url:string):string|nil
  map_remote_to_host = map_remote_to_host,
}

return M
