local M = {}

local job = require("plenary.job")
local path = require("plenary.path")

-- wrap the git command to do the right thing always
local function git(args, cwd)
  local output
  local p = job:new({
    command = "git",
    args = args,
    cwd = cwd or M.get_git_root(),
  })
  p:after_success(function(j)
    output = j:result()
  end)
  p:sync()
  return output or {}
end

local function get_remotes()
  return git({ "remote" })
end

local function get_remote_uri(remote)
  assert(remote, "remote cannot be nil")
  return git({ "remote", "get-url", remote })[1]
end

local function get_rev(revspec)
  return git({ "rev-parse", revspec })[1]
end

local function get_rev_name(revspec)
  return git({ "rev-parse", "--abbrev-ref", revspec })[1]
end

function M.is_file_in_rev(file, revspec)
  if git({ "cat-file", "-e", revspec .. ":" .. file }) then
    return true
  end
  return false
end

function M.has_file_changed(file, rev)
  if git({ "diff", rev, "--", file })[1] then
    return true
  end
  return false
end

local function is_rev_in_remote(revspec, remote)
  assert(remote, "remote cannot be nil")
  local output = git({ "branch", "--remotes", "--contains", revspec })
  for _, rbranch in ipairs(output) do
    if rbranch:match(remote) then
      return true
    end
  end
  return false
end

local allowed_chars = "[_%-%w%.]+"

-- strips the protocol (https://, git@, ssh://, etc)
local function strip_protocol(uri, errs)
  local protocol_schema = allowed_chars .. "://"
  local ssh_schema = allowed_chars .. "@"

  local stripped_uri = uri:match(protocol_schema .. "(.+)$")
    or uri:match(ssh_schema .. "(.+)$")
  if not stripped_uri then
    table.insert(
      errs,
      string.format(
        ": remote uri '%s' uses an unsupported protocol format",
        uri
      )
    )
    return nil
  end
  return stripped_uri
end

local function strip_dot_git(uri)
  return uri:match("(.+)%.git$") or uri
end

local function strip_uri(uri, errs)
  local stripped_uri = strip_protocol(uri, errs)
  return strip_dot_git(stripped_uri)
end

local function parse_host(stripped_uri, errs)
  local host_capture = "(" .. allowed_chars .. ")[:/].+$"
  local host = stripped_uri:match(host_capture)
  if not host then
    table.insert(
      errs,
      string.format(": cannot parse the hostname from uri '%s'", stripped_uri)
    )
  end
  return host
end

local function parse_port(stripped_uri, host)
  assert(host)
  local port_capture = allowed_chars .. ":([0-9]+)[:/].+$"
  return stripped_uri:match(port_capture)
end

local function parse_repo_path(stripped_uri, host, port, errs)
  assert(host)

  local pathChars = "[~/_%-%w%.%s]+"
  -- base of path capture
  local path_capture = "[:/](" .. pathChars .. ")$"

  -- if port is specified, add it to the path capture
  if port then
    path_capture = ":" .. port .. path_capture
  end

  -- add parsed host to path capture
  path_capture = allowed_chars .. path_capture

  -- parse repo path
  local repo_path = stripped_uri
    :gsub("%%20", " ") -- decode the space character
    :match(path_capture)
    :gsub(" ", "%%20") -- encode the space character
  if not repo_path then
    table.insert(
      errs,
      string.format(": cannot parse the repo path from uri '%s'", stripped_uri)
    )
    return nil
  end
  return repo_path
end

local function parse_uri(uri, errs)
  local stripped_uri = strip_uri(uri, errs)

  local host = parse_host(stripped_uri, errs)
  if not host then
    return nil
  end

  local port = parse_port(stripped_uri, host)

  local repo_path = parse_repo_path(stripped_uri, host, port, errs)
  if not repo_path then
    return nil
  end

  -- do not pass the port if it's NOT a http(s) uri since most likely the port
  -- is just an ssh port, so it's irrelevant to the git permalink construction
  -- (which is always an http url)
  if not uri:match("https?://") then
    port = nil
  end

  return { host = host, port = port, repo = repo_path }
end

function M.get_closest_remote_compatible_rev(remote)
  -- try upstream branch HEAD (a.k.a @{u})
  local upstream_rev = get_rev("@{u}")
  if upstream_rev then
    return upstream_rev
  end

  -- try HEAD
  if is_rev_in_remote("HEAD", remote) then
    local head_rev = get_rev("HEAD")
    if head_rev then
      return head_rev
    end
  end

  -- try last 50 parent commits
  for i = 1, 50 do
    local revspec = "HEAD~" .. i
    if is_rev_in_remote(revspec, remote) then
      local rev = get_rev(revspec)
      if rev then
        return rev
      end
    end
  end

  -- try remote HEAD
  local remote_rev = get_rev(remote)
  if remote_rev then
    return remote_rev
  end

  vim.notify(
    string.format(
      "Failed to get closest revision in that exists in remote '%s'",
      remote
    ),
    vim.log.levels.ERROR
  )
  return nil
end

function M.get_repo_data(remote)
  local errs = {
    string.format("Failed to retrieve repo data for remote '%s'", remote),
  }
  local remote_uri = get_remote_uri(remote)
  if not remote_uri then
    table.insert(
      errs,
      string.format(": cannot retrieve url from remote '%s'", remote)
    )
    return nil
  end

  local repo = parse_uri(remote_uri, errs)
  if not repo or vim.tbl_isempty(repo) then
    vim.notify(table.concat(errs), vim.log.levels.ERROR)
  end
  return repo
end

function M.get_git_root()
  return git(
    { "rev-parse", "--show-toplevel" },
    tostring(path:new(vim.api.nvim_buf_get_name(0)):parent())
  )[1]
end

function M.get_branch_remote()
  local remotes = get_remotes()
  if #remotes == 0 then
    vim.notify("Git repo has no remote", vim.log.levels.ERROR)
    return nil
  end
  if #remotes == 1 then
    return remotes[1]
  end

  local upstream_branch = get_rev_name("@{u}")
  if not upstream_branch then
    return nil
  end

  local remote_from_upstream_branch = upstream_branch:match(
    "^(" .. allowed_chars .. ")%/"
  )
  if not remote_from_upstream_branch then
    error(
      string.format(
        "Could not parse remote name from remote branch '%s'",
        upstream_branch
      )
    )
    return nil
  end
  for _, remote in ipairs(remotes) do
    if remote_from_upstream_branch == remote then
      return remote
    end
  end

  error(
    string.format(
      "Parsed remote '%s' from remote branch '%s' is not a valid remote",
      remote_from_upstream_branch,
      upstream_branch
    )
  )
  return nil
end

return M
