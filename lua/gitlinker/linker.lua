local range = require("gitlinker.range")
local git = require("gitlinker.git")
local path = require("gitlinker.path")
local logger = require("gitlinker.logger")
local utils = require("gitlinker.utils")

-- example:
-- git@github.com:linrongbin16/gitlinker.nvim.git
-- https://github.com/linrongbin16/gitlinker.nvim.git
--
--- @param remote_url string
--- @return {protocol:string?,host:string?,user:string?,repo:string?}
local function _parse_remote_url(remote_url)
  local PROTOS = { ["git@"] = ":", ["https://"] = "/", ["http://"] = "/" }

  local protocol = nil
  local protocol_end_pos = nil
  local host = nil
  local host_end_pos = nil
  local user = nil
  local repo = nil

  --- @type string
  local proto = nil
  --- @type string
  local proto_delimiter = nil
  --- @type integer?
  local proto_pos = nil
  for p, d in pairs(PROTOS) do
    proto_pos = utils.string_find(remote_url, p)
    if type(proto_pos) == "number" and proto_pos > 0 then
      proto = p
      proto_delimiter = d
      break
    end
  end
  if not proto_pos then
    error(
      string.format(
        "failed to parse remote url protocol:%s",
        vim.inspect(remote_url)
      )
    )
  end

  logger.debug(
    "|gitlinker.linker - _parse_remote_url| 1. remote_url:%s, proto_pos:%s (%s)",
    vim.inspect(remote_url),
    vim.inspect(proto_pos),
    vim.inspect(proto)
  )
  if type(proto_pos) == "number" and proto_pos > 0 then
    protocol_end_pos = proto_pos + string.len(proto) - 1
    protocol = remote_url:sub(1, protocol_end_pos)
    logger.debug(
      "|gitlinker.linker - _parse_remote_url| 2. remote_url:%s, proto_pos:%s (%s), protocol_end_pos:%s (%s)",
      vim.inspect(remote_url),
      vim.inspect(proto_pos),
      vim.inspect(proto),
      vim.inspect(protocol_end_pos),
      vim.inspect(protocol)
    )
    host_end_pos =
      utils.string_find(remote_url, proto_delimiter, protocol_end_pos + 1)
    if not host_end_pos then
      error(
        string.format(
          "failed to parse remote url host:%s",
          vim.inspect(remote_url)
        )
      )
    end
    host = remote_url:sub(protocol_end_pos + 1, host_end_pos - 1)
    logger.debug(
      "|gitlinker.linker - _parse_remote_url| last. remote_url:%s, proto_pos:%s (%s), protocol_end_pos:%s (%s), host_end_pos:%s (%s)",
      vim.inspect(remote_url),
      vim.inspect(proto_pos),
      vim.inspect(proto),
      vim.inspect(protocol_end_pos),
      vim.inspect(protocol),
      vim.inspect(host_end_pos),
      vim.inspect(host)
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

--- @alias gitlinker.Linker {remote_url:string,protocol:string,host:string,user:string,repo:string,rev:string,file:string,lstart:integer,lend:integer,file_changed:boolean}
--- @return gitlinker.Linker?
local function make_linker()
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

  local r = range.make_range()
  -- logger.debug("[linker - Linker:make] range:%s", vim.inspect(r))

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

  logger.debug("|linker.make_linker| o:%s", vim.inspect(o))
  return o
end

local M = {
  _parse_remote_url = _parse_remote_url,
  make_linker = make_linker,
}

return M
