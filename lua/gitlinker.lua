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
  log.setup(
    opts.get().debug,
    opts.get().console_log,
    opts.get().file_log,
    opts.get().file_log_name
  )
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
  local git_root = git.root()
  log.debug("[init.get_buf_range_url_data] git_root: %s", vim.inspect(git_root))
  if not git_root then
    log.error("Not in a git repository")
    return nil
  end
  local remote = user_opts.remote or git.get_branch_remote()
  local repo_url_data = git.get_repo_data(remote)
  log.debug(
    "[init.get_buf_range_url_data] remote: %s, repo_url_data: %s",
    vim.inspect(remote),
    vim.inspect(repo_url_data)
  )
  if not repo_url_data then
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
    log.error("'%s' does not exist in remote '%s'", buf_repo_path, remote)
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

  return vim.tbl_extend("force", repo_url_data, {
    rev = rev,
    file = buf_repo_path,
    lstart = range.lstart,
    lend = range.lend,
  })
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
    return nil
  end

  local matching_callback = M.hosts.get_matching_callback(url_data.host)
  if not matching_callback then
    return nil
  end

  local url = matching_callback(url_data)

  if user_opts.action_callback then
    user_opts.action_callback(url)
  end
  if user_opts.print_url then
    log.info(url)
  end

  return url
end

function M.get_repo_url(user_opts)
  user_opts = vim.tbl_deep_extend("force", opts.get(), user_opts or {})

  local repo_url_data =
    git.get_repo_data(git.get_branch_remote() or user_opts.remote)
  if not repo_url_data then
    return nil
  end

  local matching_callback = M.hosts.get_matching_callback(repo_url_data.host)
  if not matching_callback then
    return nil
  end

  local url = matching_callback(repo_url_data)

  if user_opts.action_callback then
    user_opts.action_callback(url)
  end
  if user_opts.print_url then
    log.info(url)
  end

  return url
end

return M
