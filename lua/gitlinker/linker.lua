local range = require("gitlinker.range")
local git = require("gitlinker.git")
local path = require("gitlinker.path")
local logger = require("gitlinker.logger")
local utils = require("gitlinker.utils")

--- @class Linker
--- @field remote_url string e.g. git@github.com:linrongbin16/gitlinker.nvim.git
--- @field protocol "git"|"http"|"https"
--- @field host string
--- @field user string
--- @field repo string
--- @field rev string
--- @field file string
--- @field lstart integer
--- @field lend integer
--- @field file_changed boolean
local Linker = {}

-- example:
-- git@github.com:linrongbin16/gitlinker.nvim.git
-- https://github.com/linrongbin16/gitlinker.nvim.git
--
--- @param remote_url string
--- @return {protocol:string?,host:string?,user:string?,repo:string?}
local function _parse_remote_url(remote_url)
  local GIT = "git"
  local HTTP = "http"
  local HTTPS = "https"
  local GIT_PROTO = "git@"
  local HTTP_PROTO = "http://"
  local HTTPS_PROTO = "https://"

  local protocol = nil
  local protocol_end_pos = nil
  local host = nil
  local host_end_pos = nil
  local user = nil
  local repo = nil
  if utils.string_startswith(remote_url, GIT_PROTO) then
    protocol = GIT
    protocol_end_pos = string.len(GIT_PROTO)
    host_end_pos = utils.string_find(remote_url, ":", protocol_end_pos + 1)
    logger.ensure(
      type(host_end_pos) == "number" and host_end_pos > protocol_end_pos + 1,
      "failed to parse remote url host:%s",
      vim.inspect(remote_url)
    )
    host = remote_url:sub(protocol_end_pos + 1, host_end_pos - 1)
  elseif
    utils.string_startswith(remote_url, HTTP_PROTO)
    or utils.string_startswith(remote_url, HTTPS_PROTO)
  then
    protocol = utils.string_startswith(remote_url, HTTP_PROTO) and HTTP or HTTPS
    protocol_end_pos = utils.string_startswith(remote_url, HTTP_PROTO)
        and string.len(HTTP_PROTO)
      or string.len(HTTPS_PROTO)
    host_end_pos = utils.string_find(remote_url, "/", protocol_end_pos + 1)
    logger.ensure(
      type(host_end_pos) == "number" and host_end_pos > protocol_end_pos + 1,
      "failed to parse remote url host:%s",
      vim.inspect(remote_url)
    )
    host = remote_url:sub(protocol_end_pos + 1, host_end_pos - 1)
  else
    logger.ensure(
      false,
      "failed to parse remote url:%s",
      vim.inspect(remote_url)
    )
  end

  local user_end_pos = utils.string_find(remote_url, "/", host_end_pos + 1)
  logger.ensure(
    type(user_end_pos) == "number" and user_end_pos > host_end_pos + 1
  )
  user = remote_url:sub(host_end_pos + 1, user_end_pos - 1)
  repo = remote_url:sub(user_end_pos + 1)
  local result = { protocol = protocol, host = host, user = user, repo = repo }
  logger.debug("linker._parse_remote_url| result:%s", vim.inspect(result))
  return result
end

--- @param r Range?
--- @return Linker?
function Linker:make(r)
  local root = git.get_root()
  if not root then
    return nil
  end

  local remote = git.get_branch_remote()
  if not remote then
    return nil
  end
  -- logger.debug("|linker - Linker:make| remote:%s", vim.inspect(remote))

  local remote_url = git.get_remote_url(remote)
  if not remote_url then
    return nil
  end

  local parsed_remote_url = _parse_remote_url(remote_url)
  local resolved_host = git.resolve_host(parsed_remote_url.host)
  if not resolved_host then
    return nil
  end

  -- logger.debug(
  --     "|linker - Linker:make| remote_url:%s",
  --     vim.inspect(remote_url)
  -- )

  local rev = git.get_closest_remote_compatible_rev(remote)
  if not rev then
    return nil
  end
  -- logger.debug("|linker - Linker:make| rev:%s", vim.inspect(rev))

  local buf_path_on_root = path.buffer_relpath(root) --[[@as string]]
  -- logger.debug(
  --     "|linker - Linker:make| root:%s, buf_path_on_root:%s",
  --     vim.inspect(root),
  --     vim.inspect(buf_path_on_root)
  -- )

  local file_in_rev_result = git.is_file_in_rev(buf_path_on_root, rev)
  if not file_in_rev_result then
    return nil
  end
  -- logger.debug(
  --     "|linker - Linker:make| file_in_rev_result:%s",
  --     vim.inspect(file_in_rev_result)
  -- )

  local buf_path_on_cwd = path.buffer_relpath() --[[@as string]]
  local file_changed = git.file_has_changed(buf_path_on_cwd, rev)
  -- logger.debug(
  --     "|linker - Linker:make| buf_path_on_cwd:%s",
  --     vim.inspect(buf_path_on_cwd)
  -- )

  if not range.is_range(r) then
    r = range.Range:make()
    -- logger.debug("[linker - Linker:make] range:%s", vim.inspect(r))
  end

  local o = {
    remote_url = remote_url,
    protocol = parsed_remote_url.protocol,
    host = resolved_host,
    user = parsed_remote_url.user,
    repo = parsed_remote_url.repo,
    rev = rev,
    file = buf_path_on_root,
    ---@diagnostic disable-next-line: need-check-nil
    lstart = r.lstart,
    ---@diagnostic disable-next-line: need-check-nil
    lend = r.lend,
    file_changed = file_changed,
  }

  logger.debug("|linker.Linker:make| o:%s", vim.inspect(o))
  return o
end

local M = {
  _parse_remote_url = _parse_remote_url,
  Linker = Linker,
}

return M
