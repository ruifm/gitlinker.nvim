local M = {}

local git = require("gitlinker.git")
local opts = require("gitlinker.opts")
local log = require("gitlinker.log")
local util = require("gitlinker.util")

-- public
M.hosts = require("gitlinker.hosts")
M.actions = require("gitlinker.actions")

--- Setup plugin option and key mapping
function M.setup(config)
  opts.setup(config)
  log.setup(opts.get())
  local mappings = opts.get().mappings
  if mappings and string.len(mappings) > 0 then
    vim.api.nvim_set_keymap(
      { "n", "v" },
      mappings,
      "<cmd>lua require('gitlinker').get_buf_range_url()<cr>",
      { noremap = true, silent = true }
    )
  end
end

local function get_buf_range_url_data(user_opts)
  local git_root = git.root_path()
  log.debug("[init.get_buf_range_url_data] git_root: %s", vim.inspect(git_root))
  if not git_root then
    log.error("Error! Not in a git repository")
    return nil
  end
  local remote = user_opts.remote or git.get_branch_remote()
  -- local repo_url_data = git.get_repo_data(remote)
  -- log.debug(
  --   "[init.get_buf_range_url_data] remote: %s, repo_url_data: %s",
  --   vim.inspect(remote),
  --   vim.inspect(repo_url_data)
  -- )
  -- if not repo_url_data then
  --   return nil
  -- end
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
    "[init.get_buf_range_url_data] buf_repo_path: %s, git_root: %s",
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
  log.debug("[init.get_buf_range_url_data] buf_path: %s", vim.inspect(buf_path))
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

local function make_git_link_url(host_url, url_data)
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
  log.debug("[init.get_buf_range_url] user_opts1: %s", vim.inspect(user_opts))
  user_opts = vim.tbl_deep_extend("force", opts.get(), user_opts or {})
  log.debug("[init.get_buf_range_url] user_opts2: %s", vim.inspect(user_opts))

  local url_data = get_buf_range_url_data(user_opts)
  if not url_data then
    log.warn("Warn! No remote found in git repository '%s'!", git.root_path())
    return nil
  end

  local host_url
  local custom_rules = opts.get().custom_rules
  if type(custom_rules) == "function" then
    host_url = custom_rules(url_data.remote_url)
  else
    local pattern_rules = opts.get().pattern_rules
    for pattern, replace in pairs(pattern_rules) do
      if string.match(url_data.remote_url, pattern) then
        host_url = string.gsub(url_data.remote_url, pattern, replace)
        break
      end
    end
  end

  if host_url == nil or string.len(host_url) <= 0 then
    log.error(
      "Error! Cannot generate git link from remote url:%s",
      url_data.remote_url
    )
    return nil
  end

  local url = make_git_link_url(host_url, url_data)

  if user_opts.action_callback then
    user_opts.action_callback(url)
  end
  if user_opts.print_url then
    log.info(url)
  end

  return url
end

return M
