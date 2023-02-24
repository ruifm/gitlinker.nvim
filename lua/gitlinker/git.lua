local M = {}

local job = require("plenary.job")
local path = require("plenary.path")
local log = require("gitlinker.log")

-- wrap the git command to do the right thing always
local function cmd(args, cwd)
  local output
  local p = job:new({
    command = "git",
    args = args,
    cwd = cwd or M.get_root(),
  })
  p:after_success(function(j)
    output = j:result()
  end)
  p:sync()
  return output or {}
end

local function get_remote()
  return cmd({ "remote" })
end

local function get_remote_url(remote)
  assert(remote, "remote cannot be nil")
  return cmd({ "remote", "get-url", remote })[1]
end

local function get_rev(revspec)
  return cmd({ "rev-parse", revspec })[1]
end

local function get_rev_name(revspec)
  return cmd({ "rev-parse", "--abbrev-ref", revspec })[1]
end

local function is_file_in_rev(file, revspec)
  if cmd({ "cat-file", "-e", revspec .. ":" .. file }) then
    return true
  end
  return false
end

local function has_file_changed(file, rev)
  if cmd({ "diff", rev, "--", file })[1] then
    return true
  end
  return false
end

local function is_rev_in_remote(revspec, remote)
  local output = cmd({ "branch", "--remotes", "--contains", revspec })
  for _, rbranch in ipairs(output) do
    if rbranch:match(remote) then
      return true
    end
  end
  return false
end

local allowed_chars = "[_%-%w%.]+"

local function get_closest_remote_compatible_rev(remote)
  assert(remote, "remote cannot be nil")

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

  return nil
end

local function get_root()
  local buf_path = path:new(vim.api.nvim_buf_get_name(0))
  local current_folder = tostring(buf_path:parent())
  local root = cmd({ "rev-parse", "--show-toplevel" }, current_folder)[1]
  log.debug("[git.root] current_folder:%s, root:%s", current_folder, root)
  return tostring(path:new(root))
end

local function get_branch_remote()
  -- origin/upstream
  local remotes = get_remote()

  if #remotes == 0 then
    log.error("Error! Git repo '%s' has no remote", get_root())
    return nil
  end

  if #remotes == 1 then
    return remotes[1]
  end

  -- origin/linrongbin16/add-rule2
  local upstream_branch = get_rev_name("@{u}")
  if not upstream_branch then
    return nil
  end

  -- origin
  local remote_from_upstream_branch =
    upstream_branch:match("^(" .. allowed_chars .. ")%/")

  if not remote_from_upstream_branch then
    log.error(
      "Error! Cannot parse remote name from remote branch '%s'",
      upstream_branch
    )
    return nil
  end

  for _, remote in ipairs(remotes) do
    if remote_from_upstream_branch == remote then
      return remote
    end
  end

  log.error(
    "Error! Parsed remote '%s' from remote branch '%s' is not a valid remote",
    remote_from_upstream_branch,
    upstream_branch
  )
  return nil
end

M.get_root = get_root
M.get_remote_url = get_remote_url
M.is_file_in_rev = is_file_in_rev
M.has_file_changed = has_file_changed
M.get_closest_remote_compatible_rev = get_closest_remote_compatible_rev
M.get_branch_remote = get_branch_remote

return M
