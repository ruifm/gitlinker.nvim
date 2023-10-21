local range = require("gitlinker.range")
local git = require("gitlinker.git")
local path = require("gitlinker.path")
local logger = require("gitlinker.logger")

--- @class Linker
--- @field remote_url string
--- @field rev string
--- @field file string
--- @field lstart integer
--- @field lend integer
--- @field file_changed boolean
local Linker = {}

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
    logger.debug("|linker - Linker:make| remote:%s", vim.inspect(remote))

    local remote_url = git.get_remote_url(remote)
    if not remote_url then
        return nil
    end
    logger.debug(
        "|linker - Linker:make| remote_url:%s",
        vim.inspect(remote_url)
    )

    local rev = git.get_closest_remote_compatible_rev(remote)
    if not rev then
        return nil
    end
    logger.debug("|linker - Linker:make| rev:%s", vim.inspect(rev))

    local buf_path_on_root = path.buffer_relpath(root) --[[@as string]]
    logger.debug(
        "|linker - Linker:make| root:%s, buf_path_on_root:%s",
        vim.inspect(root),
        vim.inspect(buf_path_on_root)
    )

    local file_in_rev_result = git.is_file_in_rev(buf_path_on_root, rev)
    if not file_in_rev_result then
        return nil
    end
    logger.debug(
        "|linker - Linker:make| file_in_rev_result:%s",
        vim.inspect(file_in_rev_result)
    )

    local buf_path_on_cwd = path.buffer_relpath() --[[@as string]]
    logger.debug(
        "|linker - Linker:make| buf_path_on_cwd:%s",
        vim.inspect(buf_path_on_cwd)
    )

    if not range.is_range(r) then
        r = range.Range:make()
        logger.debug("[linker - Linker:make] range:%s", vim.inspect(r))
    end

    local o = {
        remote_url = remote_url,
        rev = rev,
        file = buf_path_on_root,
        ---@diagnostic disable-next-line: need-check-nil
        lstart = r.lstart,
        ---@diagnostic disable-next-line: need-check-nil
        lend = r.lend,
        file_changed = git.has_file_changed(buf_path_on_cwd, rev),
    }
    return o
end

local M = {
    Linker = Linker,
}

return M
