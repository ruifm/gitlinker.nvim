local M = {}

local job = require("plenary.job")
local path = require("plenary.path")
local logger = require("gitlinker.logger")

--- @class JobResult
--- @field stdout string[]
--- @field stderr string[]

--- @param result JobResult
--- @return boolean
local function has_output(result)
  return result["stdout"]
    and type(result["stdout"]) == "table"
    and #result["stdout"] > 0
end

--- @param result JobResult
--- @return boolean
local function has_error(result)
  return result.stderr ~= nil
end

-- wrap the git command to do the right thing always
--- @param args string[]
--- @param cwd string|nil
--- @return JobResult
local function cmd(args, cwd)
  --- @type JobResult
  local result = {}
  local process = job:new({
    command = "git",
    args = args,
    cwd = cwd,
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

--- @return JobResult
local function get_remote()
  local result = cmd({ "remote" })
  logger.debug("[git.get_remote] result:%s", vim.inspect(result))
  return result
end

--- @param remote string
--- @return string|nil
local function get_remote_url(remote)
  assert(remote, "remote cannot be nil")
  local result = cmd({ "remote", "get-url", remote })
  logger.debug(
    "[git.get_remote_url] remote:%s, result:%s",
    vim.inspect(remote),
    vim.inspect(result)
  )
  return has_output(result) and result.stdout[1] or nil
end

--- @param revspec string|nil
--- @return string|nil
local function get_rev(revspec)
  local result = cmd({ "rev-parse", revspec })
  logger.debug(
    "[git.get_rev] revspec:%s, result:%s",
    vim.inspect(revspec),
    vim.inspect(result)
  )
  return has_output(result) and result.stdout[1] or nil
end

--- @param revspec string|nil
--- @return JobResult
local function get_rev_name(revspec)
  local result = cmd({ "rev-parse", "--abbrev-ref", revspec })
  logger.debug(
    "[git.get_rev_name] revspec:%s, result:%s",
    vim.inspect(revspec),
    vim.inspect(result)
  )
  return result
end

local function is_file_in_rev(file, revspec)
  local result = cmd({ "cat-file", "-e", revspec .. ":" .. file })
  logger.debug(
    "[git.is_file_in_rev] file:%s, revspec:%s, result:%s",
    vim.inspect(file),
    vim.inspect(revspec),
    vim.inspect(result)
  )
  return not has_error(result)
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
  logger.debug(
    "[git.has_file_changed] file:%s, rev:%s, result:%s",
    vim.inspect(file),
    vim.inspect(rev),
    vim.inspect(result)
  )
  return has_output(result)
end

local function is_rev_in_remote(revspec, remote)
  local result = cmd({ "branch", "--remotes", "--contains", revspec })
  logger.debug(
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

local UpstreamBranchAllowedChars = "[_%-%w%.]+"

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

  logger.error(
    "fatal: failed to get closest revision in that exists in remote '%s'",
    remote
  )
  return nil
end

local function get_root()
  local buf_path = path:new(vim.api.nvim_buf_get_name(0))
  local buf_dir = tostring(buf_path:parent())
  local result = cmd({ "rev-parse", "--show-toplevel" }, buf_dir)
  logger.debug(
    "[git.get_root] buf_path:%s, buf_dir:%s, result:%s",
    vim.inspect(buf_path),
    vim.inspect(buf_dir),
    vim.inspect(result)
  )
  if has_output(result) then
    local root = result.stdout[1]
    logger.debug("[git.root] current_folder:%s, root:%s", buf_dir, root)
    return tostring(path:new(root))
  else
    logger.debug("[git.root] current_folder:%s, root is nil", buf_dir)
    return nil
  end
end

local function get_branch_remote()
  -- origin/upstream
  --- @type JobResult
  local remote_result = get_remote()

  if type(remote_result.stdout) ~= "table" or #remote_result.stdout == 0 then
    if #remote_result.stderr > 0 then
      logger.error("%s", remote_result.stderr[1])
    else
      logger.error("fatal: git repository has no remote")
    end
    return nil
  end

  if #remote_result.stdout == 1 then
    return remote_result.stdout[1]
  end

  -- origin/linrongbin16/add-rule2
  --- @type JobResult
  local upstream_branch_result = get_rev_name("@{u}")
  if not has_output(upstream_branch_result) then
    if #upstream_branch_result.stderr > 0 then
      logger.error("%s", upstream_branch_result.stderr[1])
    else
      logger.error("fatal: git branch has no remote")
    end
    return nil
  end

  --- @type string
  local upstream_branch = upstream_branch_result.stdout[1]
  -- origin
  --- @type string
  local remote_from_upstream_branch =
    upstream_branch:match("^(" .. UpstreamBranchAllowedChars .. ")%/")

  if not remote_from_upstream_branch then
    logger.error(
      "fatal: cannot parse remote name from remote branch '%s'",
      upstream_branch
    )
    return nil
  end

  local remotes = remote_result.stdout
  for _, remote in ipairs(remotes) do
    if remote_from_upstream_branch == remote then
      return remote
    end
  end

  logger.error(
    "fatal: parsed remote '%s' from remote branch '%s' is not a valid remote",
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
