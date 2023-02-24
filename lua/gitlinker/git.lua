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

local function string_split(s, sep)
  -- by default, split by whitespace
  if sep == nil then
    sep = "%s"
  end
  local splits = {}
  for i in string.gmatch(s, "([^" .. sep .. "]+)") do
    table.insert(splits, i)
  end
  return splits
end

local function to_positive(n)
  if n < 0 then
    return -n
  else
    return n
  end
end

local function has_intersection(range1, range2)
  if range1.lend < range2.lstart then
    return false
  end
  if range1.start > range2.lend then
    return false
  end
  return true
end

local function has_file_changed(file, rev, lstart, lend)
  local diffs = cmd({ "diff", rev, "--", file })
  log.debug(
    "[git.has_file_changed] file:%s, rev:%s, lstart:%s, lend:%s, diffs:%s",
    vim.inspect(file),
    vim.inspect(rev),
    vim.inspect(lstart),
    vim.inspect(lend),
    vim.inspect(diffs)
  )
  if #diffs >= 5 then
    local diff = diffs[5]
    -- The 5th line is line diff info, for example:
    -- `@@ -44,17 +44,22 @@ local function is_file_in_rev(file, revspec)`
    if diff and string.len(diff) > 0 then
      local splits = string_split(diff)
      local old = splits[2] -- -44,17
      local new = splits[3] -- +44,22
      local old_splits = string_split(old, ",")
      local new_splits = string_split(new, ",")
      local old_start = to_positive(tonumber(old_splits[1]))
      local old_end = old_start + to_positive(tonumber(old_splits[2]))
      local new_start = to_positive(tonumber(new_splits[1]))
      local new_end = new_start + to_positive(tonumber(new_splits[2]))
      local diff_start = math.min(old_start, new_start)
      local diff_end = math.max(old_end, new_end)
      local diff_range = {
        lstart = diff_start,
        lend = diff_end,
      }
      local line_range = {
        lstart = lstart,
        lend = lend,
      }
      log.debug(
        "[git.has_file_changed] splits:%s, old:%s, new:%s, old_splits:%s, new_splits:%s, diff_range:%s, line_range:%s",
        vim.inspect(splits),
        vim.inspect(old),
        vim.inspect(new),
        vim.inspect(old_splits),
        vim.inspect(new_splits),
        vim.inspect(diff_range),
        vim.inspect(line_range)
      )
      if has_intersection(diff_range, line_range) then
        return true
      end
    end
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

  log.error(
    "Error! Failed to get closest revision in that exists in remote '%s'",
    remote
  )
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
