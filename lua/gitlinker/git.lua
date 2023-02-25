local M = {}

local job = require("plenary.job")
local path = require("plenary.path")
local log = require("gitlinker.log")

-- wrap the git command to do the right thing always
local function cmd(args, cwd)
  local result = {}
  local process = job:new({
    command = "git",
    args = args,
    cwd = cwd or M.get_root(),
  })
  process:after_success(function(j)
    result.stdout = j:result()
  end)
  process:after_failure(function(j)
    result.stderr = j:stderr_result()
  end)
  process:sync()
  return result
end

local function get_remote()
  local result = cmd({ "remote" })
  log.debug("[git.get_remote] result:%s", vim.inspect(result))
  return result.stdout
end

local function get_remote_url(remote)
  assert(remote, "remote cannot be nil")
  local result = cmd({ "remote", "get-url", remote })
  log.debug(
    "[git.get_remote_url] remote:%s, result:%s",
    vim.inspect(remote),
    vim.inspect(result)
  )
  return result.stdout[1]
end

local function get_rev(revspec)
  local result = cmd({ "rev-parse", revspec })
  log.debug(
    "[git.get_rev] revspec:%s, result:%s",
    vim.inspect(revspec),
    vim.inspect(result)
  )
  return result.stdout[1]
end

local function get_rev_name(revspec)
  local result = cmd({ "rev-parse", "--abbrev-ref", revspec })
  log.debug(
    "[git.get_rev_name] revspec:%s, result:%s",
    vim.inspect(revspec),
    vim.inspect(result)
  )
  return result.stdout[1]
end

local function is_file_in_rev(file, revspec)
  local result = cmd({ "cat-file", "-e", revspec .. ":" .. file })
  log.debug(
    "[git.is_file_in_rev] file:%s, revspec:%s, result:%s",
    vim.inspect(file),
    vim.inspect(revspec),
    vim.inspect(result)
  )
  return result.stderr == nil
end

-- local function string_split(s, sep)
--   -- by default, split by whitespace
--   if sep == nil then
--     sep = "%s"
--   end
--   local splits = {}
--   for i in string.gmatch(s, "([^" .. sep .. "]+)") do
--     table.insert(splits, i)
--   end
--   return splits
-- end
--
-- local function to_positive(n)
--   if n < 0 then
--     return -n
--   else
--     return n
--   end
-- end

local function has_file_changed(file, rev)
  local result = cmd({ "diff", rev, "--", file })
  log.debug(
    "[git.has_file_changed] file:%s, rev:%s, result:%s",
    vim.inspect(file),
    vim.inspect(rev),
    vim.inspect(result)
  )
  return type(result.stdout) == "table" and #result.stdout > 0
end

local function is_rev_in_remote(revspec, remote)
  local result = cmd({ "branch", "--remotes", "--contains", revspec })
  log.debug(
    "[git.is_rev_in_remote] revspec:%s, remote:%s, result:%s",
    vim.inspect(revspec),
    vim.inspect(remote),
    vim.inspect(result)
  )
  local output = result.stdout
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

  log.error(
    "Error! Failed to get closest revision in that exists in remote '%s'",
    remote
  )
  return nil
end

local function get_root()
  local buf_path = path:new(vim.api.nvim_buf_get_name(0))
  local buf_dir = tostring(buf_path:parent())
  local result = cmd({ "rev-parse", "--show-toplevel" }, buf_dir)
  log.debug(
    "[git.get_root] buf_path:%s, buf_dir:%s, result:%s",
    vim.inspect(buf_path),
    vim.inspect(buf_dir),
    vim.inspect(result)
  )
  local root = result.stdout[1]
  log.debug("[git.root] current_folder:%s, root:%s", buf_dir, root)
  return tostring(path:new(root))
end

local function get_branch_remote()
  -- origin/upstream
  local remotes = get_remote()

  if type(remotes) ~= "table" or #remotes == 0 then
    log.error("Error! Git repository has no remote")
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
