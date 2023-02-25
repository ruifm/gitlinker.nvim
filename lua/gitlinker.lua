local git = require("gitlinker.git")
local log = require("gitlinker.log")
local util = require("gitlinker.util")
local keys = require("gitlinker.keys")

local DEFAULTS = {
  -- system/clipboard
  action = require("gitlinker.actions").system,
  -- print message(git host url) in command line
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

  -- enable debug
  debug = false,
  -- write logs to console(command line)
  console_log = true,
  -- write logs to file
  file_log = false,
  -- file name to write logs, working with `file_log=true`
  file_log_name = "gitlinker.log",
}

local opts = {}

--- Setup configs
local function setup(configs)
  opts = vim.tbl_deep_extend("force", DEFAULTS, configs or {})
  log.setup(opts.debug, opts.console_log, opts.file_log, opts.file_log_name)
  keys.setup(opts.mapping)
  log.debug("[setup] opts: %s", vim.inspect(opts))
end

local function make_link_data()
  local root = git.get_root()
  if not root then
    log.error("Error! Not in a git repository")
    return nil
  end

  local remote = git.get_branch_remote()
  if not remote then
    return nil
  end

  local remote_url = git.get_remote_url(remote)
  if not remote_url then
    log.error("Error! Failed to get remote url by remote '%s'", remote)
    return nil
  end

  local rev = git.get_closest_remote_compatible_rev(remote)
  if not rev then
    return nil
  end

  local buf_path_on_root = util.relative_path(root)
  log.debug(
    "[make_link_data] buf_path_on_root: %s, git_root: %s",
    vim.inspect(buf_path_on_root),
    vim.inspect(root)
  )
  if not git.is_file_in_rev(buf_path_on_root, rev) then
    log.error(
      "Error! '%s' does not exist in remote '%s'",
      buf_path_on_root,
      remote
    )
    return nil
  end

  local buf_path_on_cwd = util.relative_path()
  local range = util.line_range()
  log.debug(
    "[make_link_data] buf_path_on_cwd:%s, range:%s",
    vim.inspect(buf_path_on_cwd),
    vim.inspect(range)
  )

  -- if git.has_file_changed(buf_path_on_cwd, rev) then
  --   log.info(
  --     "Computed Line numbers are probably wrong because '%s' has changes",
  --     buf_path_on_cwd
  --   )
  -- end

  return {
    remote_url = remote_url,
    rev = rev,
    file = buf_path_on_root,
    lstart = range.lstart,
    lend = range.lend,
    file_changed = git.has_file_changed(buf_path_on_cwd, rev),
  }
end

local function map_remote_to_host(remote_url)
  local custom_rules = opts.custom_rules
  if type(custom_rules) == "function" then
    return custom_rules(remote_url)
  else
    local pattern_rules = opts.pattern_rules
    for i, group in ipairs(pattern_rules) do
      for pattern, replace in pairs(group) do
        log.debug(
          "[map_remote_to_host] map group[%d], pattern:'%s', replace:'%s'",
          i,
          pattern,
          replace
        )
        if string.match(remote_url, pattern) then
          local host_url = string.gsub(remote_url, pattern, replace)
          log.debug(
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

local function make_sharable_permalinks(host_url, url_data)
  local url = host_url .. url_data.rev .. "/" .. url_data.file
  if not url_data.lstart then
    return url
  end
  url = url .. "#L" .. url_data.lstart
  if url_data.lend and url_data.lend ~= url_data.lstart then
    url = url .. "-L" .. url_data.lend
  end
  return url
end

--- Get the url for the buffer with selected lines
local function link(user_opts)
  log.debug("[make_link] before merge, user_opts: %s", vim.inspect(user_opts))
  user_opts = vim.tbl_deep_extend("force", opts, user_opts or {})
  log.debug("[make_link] after merge, user_opts: %s", vim.inspect(user_opts))

  local url_data = make_link_data()
  if not url_data then
    return nil
  end

  local host_url = map_remote_to_host(url_data.remote_url)

  if host_url == nil or string.len(host_url) <= 0 then
    log.error(
      "Error! Cannot generate git link from remote url:%s",
      url_data.remote_url
    )
    return nil
  end

  local url = make_sharable_permalinks(host_url, url_data)

  if user_opts.action then
    user_opts.action(url)
  end
  if user_opts.message then
    local msg = url_data.file_changed
        and string.format("%s (lines can be wrong due to file change)", url)
      or url
    log.info(msg)
  end

  return url
end

local M = {
  setup = setup,
  link = link,
  map_remote_to_host = map_remote_to_host,
}

return M
