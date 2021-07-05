local M = {}

local git = require("gitlinker.git")
local buffer = require("gitlinker.buffer")
local mappings = require("gitlinker.mappings")
local opts = require("gitlinker.opts")

-- public
M.hosts = require("gitlinker.hosts")
M.actions = require("gitlinker.actions")

--- Setup the plugin configuration
--
-- Sets the options
-- Sets the hosts callbacks
-- Sets the mappings
--
-- @param config table with the schema
-- {
--   opts = {
--    remote = "<remotename>", -- force the use of a specific remote
--    add_current_line_on_normal_mode = true/false, -- add the line nr to the url
--    url_callback = <func> -- what to do with the url
--   }, -- check gitlinker/opts for the default values
--  callbacks = {
--    ["githostname.tld"] = <func> -- where <func> is a function that takes a
--    url_data table and returns the url
--   },
--  mappings = "<keys>"-- keys for normal and visual mode keymaps
-- }
-- @param user_opts a table to override options passed in M.setup()
function M.setup(config)
  if config then
    opts.setup(config.opts)
    M.hosts.callbacks = vim.tbl_deep_extend(
      "force",
      M.hosts.callbacks,
      config.callbacks or {}
    )
    mappings.set(config.mappings)
  else
    opts.setup()
    mappings.set()
  end
end

local function get_url_data(mode, user_opts)
  local remote = user_opts.remote or git.get_branch_remote()
  if not remote then
    return nil
  end

  local repo = git.get_repo_data(remote)
  if not repo or vim.tbl_isempty(repo) then
    return nil
  end

  local buf_repo_path = buffer.get_relative_path(git.get_git_root())

  local rev = git.get_closest_remote_compatible_rev(buf_repo_path, remote)
  if not rev then
    return nil
  end

  local range = buffer.get_range(
    mode or "n",
    user_opts.add_current_line_on_normal_mode
  )

  return {
    host = repo.host,
    repo = repo.path,
    port = repo.port,
    rev = rev,
    file = buf_repo_path,
    lstart = range.lstart,
    lend = range.lend,
  }
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
function M.get_buf_range_url(mode, user_opts)
  user_opts = vim.tbl_deep_extend("force", opts.get(), user_opts or {})

  local url_data = get_url_data(mode, user_opts)
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
    print(url)
  end

  return url
end

return M
