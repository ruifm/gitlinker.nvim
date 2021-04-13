local M = {}

local git = require 'gitlinker.git'
local buffer = require 'gitlinker.buffer'
local mappings = require 'gitlinker.mappings'
local opts = require 'gitlinker.opts'

-- public
M.hosts = require 'gitlinker.hosts'
M.actions = require 'gitlinker.actions'

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
    if config.opts then opts = vim.tbl_extend('force', opts, config.opts) end
    if config.callbacks then
      M.hosts.callbacks = vim.tbl_extend('force', M.hosts.callbacks,
                                         config.callbacks)
    end
  end
  mappings.set(opts.mappings)
end

local function get_url_data(mode)
  local remote = opts.remote or git.get_branch_remote()
  if not remote then return nil end

  local repo = git.get_repo(remote)
  if not repo then return nil end

  local buf_repo_path = buffer.get_relative_path(git.get_git_root())

  local rev = git.get_closest_remote_compatible_rev(buf_repo_path, remote)
  if not rev then return nil end

  local range = buffer.get_range(mode, opts.add_current_line_on_normal_mode)

  return {
    host = repo.host,
    repo = repo.path,
    rev = rev,
    file = buf_repo_path,
    lstart = range.lstart,
    lend = range.lend
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
  if user_opts then opts = vim.tbl_extend('force', opts, user_opts) end

  local url_data = get_url_data(mode)
  if not url_data then return nil end

  local matching_callback = M.hosts.get_matching_callback(url_data.host)
  if not matching_callback then return nil end

  local url = matching_callback(url_data)

  if opts.action_callback then opts.action_callback(url) end
  print(url)

  return url
end

return M
