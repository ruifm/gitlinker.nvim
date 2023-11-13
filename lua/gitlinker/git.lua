local logger = require("gitlinker.logger")
local spawn = require("gitlinker.spawn")

--- @class CmdResult
--- @field stdout string[]
--- @field stderr string[]
local CmdResult = {}

--- @return CmdResult
function CmdResult:new()
    local o = {
        stdout = {},
        stderr = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @return boolean
function CmdResult:has_out()
    return type(self.stdout) == "table" and #self.stdout > 0
end

--- @return boolean
function CmdResult:has_err()
    return type(self.stderr) == "table" and #self.stderr > 0
end

--- @param default string
function CmdResult:print_err(default)
    if self:has_err() then
        for _, e in ipairs(self.stderr) do
            logger.err("%s", e)
        end
    else
        logger.err("fatal: %s", default)
    end
end

-- wrap the git command to do the right thing always
--- @package
--- @param args string[]
--- @param cwd string?
--- @return CmdResult
local function cmd(args, cwd)
    local result = CmdResult:new()

    local sp = spawn.Spawn:make(args, {
        cwd = cwd or vim.fn.getcwd(),
        on_stdout = function(line)
            if type(line) == "string" then
                table.insert(result.stdout, line)
            end
        end,
        on_stderr = function(line)
            if type(line) == "string" then
                table.insert(result.stderr, line)
            end
        end,
    }) --[[@as Spawn]]
    sp:run()

    -- logger.debug(
    --     "|git.cmd| args:%s, cwd:%s, result:%s",
    --     vim.inspect(args),
    --     vim.inspect(cwd),
    --     vim.inspect(result)
    -- )
    return result
end

--- @package
--- @return string[]|nil
local function _get_remote()
    local result = cmd({ "git", "remote" })
    -- logger.debug("|git._get_remote| result:%s", vim.inspect(result))
    if type(result.stdout) ~= "table" or #result.stdout == 0 then
        result:print_err("fatal: git repo has no remote")
        return nil
    end
    return result.stdout
end

--- @param remote string
--- @return string?
local function get_remote_url(remote)
    assert(remote, "remote cannot be nil")
    local result = cmd({ "git", "remote", "get-url", remote })
    -- logger.debug(
    --     "|git.get_remote_url| remote:%s, result:%s",
    --     vim.inspect(remote),
    --     vim.inspect(result)
    -- )
    if not result:has_out() then
        result:print_err(
            "fatal: failed to get remote url by remote '" .. remote .. "'"
        )
        return nil
    end
    return result.stdout[1]
end

--- @package
--- @param revspec string?
--- @return string?
local function _get_rev(revspec)
    local result = cmd({ "git", "rev-parse", revspec })
    -- logger.debug(
    --     "|git._get_rev| revspec:%s, result:%s",
    --     vim.inspect(revspec),
    --     vim.inspect(result)
    -- )
    return result:has_out() and result.stdout[1] or nil
end

--- @package
--- @param revspec string
--- @return string?
local function _get_rev_name(revspec)
    local result = cmd({ "git", "rev-parse", "--abbrev-ref", revspec })
    -- logger.debug(
    --     "|git._get_rev_name| revspec:%s, result:%s",
    --     vim.inspect(revspec),
    --     vim.inspect(result)
    -- )
    if not result:has_out() then
        result:print_err("fatal: git branch has no remote")
        return nil
    end
    return result.stdout[1]
end

--- @param file string
--- @param revspec string
--- @return boolean
local function is_file_in_rev(file, revspec)
    local result = cmd({ "git", "cat-file", "-e", revspec .. ":" .. file })
    -- logger.debug(
    --     "|git.is_file_in_rev| file:%s, revspec:%s, result:%s",
    --     vim.inspect(file),
    --     vim.inspect(revspec),
    --     vim.inspect(result)
    -- )
    if result:has_err() then
        result:print_err(
            "fatal: '"
                .. file
                .. "' does not exist in remote '"
                .. revspec
                .. "'"
        )
        return false
    end
    return true
end

--- @param file string
--- @param rev string
--- @return boolean
local function has_file_changed(file, rev)
    local result = cmd({ "git", "diff", rev, "--", file })
    -- logger.debug(
    --     "|git.has_file_changed| file:%s, rev:%s, result:%s",
    --     vim.inspect(file),
    --     vim.inspect(rev),
    --     vim.inspect(result)
    -- )
    return result:has_out()
end

--- @package
--- @param revspec string
--- @param remote string
--- @return boolean
local function _is_rev_in_remote(revspec, remote)
    local result = cmd({ "git", "branch", "--remotes", "--contains", revspec })
    -- logger.debug(
    --     "|git.is_rev_in_remote| revspec:%s, remote:%s, result:%s",
    --     vim.inspect(revspec),
    --     vim.inspect(remote),
    --     vim.inspect(result)
    -- )
    local output = result.stdout
    for _, rbranch in ipairs(output) do
        if rbranch:match(remote) then
            return true
        end
    end
    return false
end

--- @param remote string
--- @return string?
local function get_closest_remote_compatible_rev(remote)
    assert(remote, "remote cannot be nil")

    -- try upstream branch HEAD (a.k.a @{u})
    local upstream_rev = _get_rev("@{u}")
    if upstream_rev then
        return upstream_rev
    end

    -- try HEAD
    if _is_rev_in_remote("HEAD", remote) then
        local head_rev = _get_rev("HEAD")
        if head_rev then
            return head_rev
        end
    end

    -- try last 50 parent commits
    for i = 1, 50 do
        local revspec = "HEAD~" .. i
        if _is_rev_in_remote(revspec, remote) then
            local rev = _get_rev(revspec)
            if rev then
                return rev
            end
        end
    end

    -- try remote HEAD
    local remote_rev = _get_rev(remote)
    if remote_rev then
        return remote_rev
    end

    logger.err(
        "fatal: failed to get closest revision in that exists in remote '%s'",
        remote
    )
    return nil
end

--- @return string?
local function get_root()
    local buf_path = vim.api.nvim_buf_get_name(0)
    local buf_dir = vim.fn.fnamemodify(buf_path, ":p:h")
    local result = cmd({ "git", "rev-parse", "--show-toplevel" }, buf_dir)
    -- logger.debug(
    --     "|git.get_root| buf_path:%s, buf_dir:%s, result:%s",
    --     vim.inspect(buf_path),
    --     vim.inspect(buf_dir),
    --     vim.inspect(result)
    -- )
    if not result:has_out() then
        result:print_err("fatal: not in a git repository")
        return nil
    end
    return result.stdout[1]
end

--- @return string?
local function get_branch_remote()
    -- origin/upstream
    local remotes = _get_remote()
    if not remotes then
        return nil
    end

    if #remotes == 1 then
        return remotes[1]
    end

    -- origin/linrongbin16/add-rule2
    local upstream_branch = _get_rev_name("@{u}")
    if not upstream_branch then
        return nil
    end

    local upstream_branch_allowed_chars = "[_%-%w%.]+"

    -- origin
    local remote_from_upstream_branch =
        upstream_branch:match("^(" .. upstream_branch_allowed_chars .. ")%/")

    if not remote_from_upstream_branch then
        logger.err(
            "fatal: cannot parse remote name from remote branch '%s'",
            upstream_branch
        )
        return nil
    end

    for _, remote in ipairs(remotes) do
        if remote_from_upstream_branch == remote then
            return remote
        end
    end

    logger.err(
        "fatal: parsed remote '%s' from remote branch '%s' is not a valid remote",
        remote_from_upstream_branch,
        upstream_branch
    )
    return nil
end

local M = {
    CmdResult = CmdResult,
    _get_remote = _get_remote,
    _get_rev = _get_rev,
    _get_rev_name = _get_rev_name,
    get_root = get_root,
    get_remote_url = get_remote_url,
    is_file_in_rev = is_file_in_rev,
    has_file_changed = has_file_changed,
    get_closest_remote_compatible_rev = get_closest_remote_compatible_rev,
    get_branch_remote = get_branch_remote,
}

return M
