local M = {}

local git = require("gitlinker.git")
local log = require("gitlinker.log")
local util = require("gitlinker.util")
local keys = require("gitlinker.keys")

local DEFAULTS = {
  -- open_in_browser/copy_to_clipboard
  action = require("gitlinker.actions").open_in_browser,
  -- print message(git host url) in command line
  message = true,
  -- key mapping
  mapping = "<leader>gl",
  -- regex pattern based rules
  pattern_rules = {
    -- git@github.(com|*):linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
    {
      ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
      ["^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
    },
    -- http(s)://github.(com|*)/linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
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
function M.setup(configs)
  opts = vim.tbl_deep_extend("force", DEFAULTS, configs or {})
  log.debug("[setup] opts: %s", vim.inspect(opts))
  log.setup(opts.debug, opts.console_log, opts.file_log, opts.file_log_name)
  keys.setup(opts.mapping)
end

local function make_linker_data()
  local git_root = git.get_root()
  log.debug("[make_linker_data] git_root: %s", vim.inspect(git_root))
  if not git_root then
    log.error("Error! Not in a git repository")
    return nil
  end
  local remote = git.get_branch_remote()
  log.debug("[make_linker_data] git_root: %s", vim.inspect(git_root))
  local remote_url = git.get_remote_url(remote)
  if not remote_url then
    return nil
  end

  local rev = git.get_closest_remote_compatible_rev(remote)
  if not rev then
    return nil
  end

  local buf_repo_path = util.relative_path(git_root)
  log.debug(
    "[make_linker_data] buf_repo_path: %s, git_root: %s",
    vim.inspect(buf_repo_path),
    vim.inspect(git_root)
  )
  if not git.is_file_in_rev(buf_repo_path, rev) then
    log.error(
      "Error! '%s' does not exist in remote '%s'",
      buf_repo_path,
      remote
    )
    return nil
  end

  local buf_path = util.relative_path()
  log.debug("[make_linker_data] buf_path: %s", vim.inspect(buf_path))
  if git.has_file_changed(buf_path, rev) then
    log.info(
      "Computed Line numbers are probably wrong because '%s' has changes",
      buf_path
    )
  end
  local range = util.selected_line_range()

  return {
    remote_url = remote_url,
    rev = rev,
    file = buf_repo_path,
    lstart = range.lstart,
    lend = range.lend,
  }
end

function M.map_remote_to_host(remote_url)
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

function M.make_git_link_url(host_url, url_data)
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

--- Retrieves the url for the selected buffer range
--
-- Gets the url data elements
-- Passes it to the matching host callback
-- Retrieves the url from the host callback
-- Passes the url to the url callback
-- Prints the url
--
-- @param mode vim's mode this function was called on. Either 'v' or 'n'
-- @param user_opts a table to override options passed
--
-- @returns The url string
function M.get_buf_range_url(user_opts)
  log.debug("[get_buf_range_url] user_opts1: %s", vim.inspect(user_opts))
  user_opts = vim.tbl_deep_extend("force", opts, user_opts or {})
  log.debug("[get_buf_range_url] user_opts2: %s", vim.inspect(user_opts))

  local url_data = make_linker_data()
  if not url_data then
    log.warn("Warn! No remote found in git repository '%s'!", git.get_root())
    return
  end

  local host_url = M.map_remote_to_host(url_data.remote_url)

  if host_url == nil or string.len(host_url) <= 0 then
    log.error(
      "Error! Cannot generate git link from remote url:%s",
      url_data.remote_url
    )
    return
  end

  local url = M.make_git_link_url(host_url, url_data)

  if user_opts.action then
    user_opts.action(url)
  end
  if user_opts.message then
    log.info(url)
  end
end

return M
