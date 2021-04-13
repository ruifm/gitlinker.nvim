local M = {}

local job = require 'plenary.job'
local path = require 'plenary.path'

local function get_remotes()
  local remotes
  local p = job:new({command = "git", args = {"remote"}})
  p:after_success(function(j) remotes = j:result() end)
  p:sync()
  return remotes
end

local function get_remote_uri(remote)
  assert(remote, "remote cannot be nil")
  local remote_uri
  local p = job:new({command = "git", args = {"remote", "get-url", remote}})
  p:after_success(function(j) remote_uri = j:result()[1] end)
  p:sync()
  return remote_uri
end

local function get_rev(revspec)
  local rev
  local p = job:new({command = "git", args = {"rev-parse", revspec}})
  p:after_success(function(j) rev = j:result()[1] end)
  p:sync()
  return rev
end

local function is_file_in_rev(file, revspec)
  local is_in_rev = false
  local p = job:new({
    command = "git",
    args = {"cat-file", "-e", revspec .. ":" .. file}
  })
  p:after_success(function() is_in_rev = true end)
  p:sync()
  return is_in_rev
end

local function has_file_changed(file, rev)
  local has_changed = false
  local p = job:new({
    command = "git",
    args = {"diff", "--exit-code", rev, "--", file}
  })
  p:after_failure(function() has_changed = true end)
  p:sync()
  return has_changed
end

local function is_rev_in_remote(revspec, remote)
  assert(remote, "remote cannot be nil")
  local is_in_remote = false
  local p = job:new({
    command = "git",
    args = {"branch", "--remotes", "--contains", revspec}
  })
  p:after_success(function(j)
    local output = j:result()
    for _, rbranch in ipairs(output) do
      if rbranch:match(remote) then
        is_in_remote = true
        return
      end
    end
  end)
  p:sync()
  return is_in_remote
end

local function parse_uri(uri, errs)
  local chars = "[_%-%w%.]+"
  local protocol_schema = "%g+[/@]"
  local host_schema = chars .. "%." .. chars
  local path_schema = "" .. chars .. "/" .. chars
  local host_capture = protocol_schema .. '(' .. host_schema .. ")[:/]" ..
                         path_schema .. "%.git$"
  local path_capture =
    protocol_schema .. host_schema .. "[:/](" .. path_schema .. ")%.git$"
  local repo = {host = uri:match(host_capture), path = uri:match(path_capture)}
  if not repo.host then
    table.insert(errs, string.format(
                   ": cannot parse the host name from uri '%s'", uri))
  end
  return repo
end

local function is_file_compatible_with_revspec(buf_repo_path, revspec, errs)
  if not is_file_in_rev(buf_repo_path, revspec) then
    table.insert(errs,
                 string.format(": '%s' is not in '%s'", buf_repo_path, revspec))
    return false
  end

  local buf_path = path:new(buf_repo_path):make_relative()
  if has_file_changed(buf_path, revspec) then
    table.insert(errs, string.format(": '%s' has changed relative to '%s'",
                                     buf_repo_path, revspec))
    return false
  end

  return true
end

local function get_rev_for_revspec_if_contains_file(buf_repo_path, revspec, errs)
  local rev = get_rev(revspec)
  if not rev then
    table.insert(errs, string.format(": could not retrieve revision for '%s'",
                                     revspec))
    return nil
  end

  if not is_file_compatible_with_revspec(buf_repo_path, revspec, errs) then
    return nil
  end
  return rev
end

function M.get_closest_remote_compatible_rev(buf_repo_path, remote)
  local errs = {"Failed get appropriate revision"}
  -- try HEAD
  if is_rev_in_remote("HEAD", remote) then
    local head_rev = get_rev_for_revspec_if_contains_file(buf_repo_path, "HEAD",
                                                          errs)
    if head_rev then return head_rev end
  else
    table.insert(errs,
                 string.format(": current 'HEAD' not in remote '%s'", remote))
  end

  -- try upstream branch HEAD (a.k.a @{u})
  local upstream_rev = get_rev_for_revspec_if_contains_file(buf_repo_path,
                                                            "@{u}", errs)
  if upstream_rev then return upstream_rev end

  -- try last 50 parent commits
  for i = 1, 50 do
    local revspec = "HEAD~" .. i
    if is_rev_in_remote(revspec, remote) then
      local rev = get_rev_for_revspec_if_contains_file(buf_repo_path, revspec,
                                                       {})
      if rev then return rev end
    end

  end

  -- try remote HEAD
  local remote_rev = get_rev_for_revspec_if_contains_file(buf_repo_path, remote,
                                                          errs)
  if remote_rev then return remote_rev end

  error(table.concat(errs))
  return nil
end

function M.get_repo(remote)
  local errs = {
    string.format("Failed to retrieve repo data for remote '%s'", remote)
  }
  local remote_uri = get_remote_uri(remote)
  if not remote_uri then
    table.insert(errs, string.format(": cannot retrieve url from remote '%s'",
                                     remote))
    return nil
  end

  local repo = parse_uri(remote_uri, errs)
  if not repo then error(table.concat(errs)) end
  return repo
end

function M.get_git_root()
  local root
  local p = job:new({command = "git", args = {"rev-parse", "--show-toplevel"}})
  p:after_success(function(j) root = j:result()[1] end)
  p:sync()
  return root
end

function M.get_branch_remote()
  local remotes = get_remotes()
  if #remotes == 0 then
    error("Git repo has no remote")
    return nil
  end
  if #remotes == 1 then return remotes[1] end

  for _, remote in ipairs(remotes) do
    -- try upstream branch HEAD (a.k.a @{u})
    local upstream_revspec = "@{u}"
    if get_rev(upstream_revspec) and is_rev_in_remote(upstream_revspec, remote) then
      return remote
    end

    -- try last 50 parent commits
    for i in 0, 50 do
      local revspec = "HEAD~" .. i
      if is_rev_in_remote(revspec, remote) then return remote end

    end
  end

  error [[
      Multiple remotes available and all of them can be used.
      Please choose one of them using require'gitlinker'.setup({remote='<remotename>'})
    ]]
  return nil
end

return M
