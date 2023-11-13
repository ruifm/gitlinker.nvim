local logger = require("gitlinker.logger")

-- normalize path slash from '\\' to '/'
--- @param p string
--- @return string
local function normalize(p)
    local result = vim.fn.expand(p)
    if string.match(result, [[\\]]) then
        result = string.gsub(result, [[\\]], [[/]])
    end
    if string.match(result, [[\]]) then
        result = string.gsub(result, [[\]], [[/]])
    end
    return vim.trim(result)
end

--- @param cwd string?
--- @return string?
local function buffer_relpath(cwd)
    cwd = cwd or vim.fn.getcwd()
    cwd = vim.fn.resolve(cwd)
    cwd = normalize(cwd)

    local bufpath = vim.api.nvim_buf_get_name(0)
    bufpath = vim.fn.resolve(bufpath)
    bufpath = normalize(bufpath)

    -- logger.debug(
    --     "|path.buffer_relpath| enter, cwd:%s, bufpath:%s",
    --     vim.inspect(cwd),
    --     vim.inspect(bufpath)
    -- )

    local result = nil
    if
        string.len(bufpath) >= string.len(cwd)
        and bufpath:sub(1, #cwd) == cwd
    then
        result = bufpath:sub(#cwd + 1)
        if result:sub(1, 1) == "/" or result:sub(1, 1) == "\\" then
            result = result:sub(2)
        end
    end
    -- logger.debug("|path.buffer_relpath| result:%s", vim.inspect(result))
    return result
end

local M = {
    normalize = normalize,
    buffer_relpath = buffer_relpath,
}

return M
