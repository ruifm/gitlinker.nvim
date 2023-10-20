local logger = require("gitlinker.logger")

--- @param cwd string?
--- @return string?
local function relative_path(cwd)
    logger.debug(
        "|util.relative_path| cwd1(%s):%s",
        vim.inspect(type(cwd)),
        vim.inspect(cwd)
    )

    local buf_path = vim.api.nvim_buf_get_name(0)
    if cwd == nil or string.len(cwd) <= 0 then
        cwd = vim.fn.getcwd()
    end
    -- get real path from possibly symlink
    cwd = vim.fn.resolve(cwd)
    -- normalize path slash from '\\' to '/'
    if cwd:find("\\") then
        cwd = cwd:gsub("\\\\", "/")
        cwd = cwd:gsub("\\", "/")
    end
    if buf_path:find("\\") then
        buf_path = buf_path:gsub("\\\\", "/")
        buf_path = buf_path:gsub("\\", "/")
    end
    logger.debug(
        "|util.relative_path| buf_path(%s):%s, cwd(%s):%s",
        vim.inspect(type(buf_path)),
        vim.inspect(buf_path),
        vim.inspect(type(cwd)),
        vim.inspect(cwd)
    )

    local relpath = nil
    if buf_path:sub(1, #cwd) == cwd then
        relpath = buf_path:sub(#cwd + 1, -1)
        if relpath:sub(1, 1) == "/" or relpath:sub(1, 1) == "\\" then
            relpath = relpath:sub(2, -1)
        end
    end
    logger.debug(
        "|util.relative_path| relpath(%s):%s",
        vim.inspect(type(relpath)),
        vim.inspect(relpath)
    )
    return relpath
end

local function is_visual_mode(m)
    return type(m) == "string" and m:upper() == "V"
        or m:upper() == "CTRL-V"
        or m:upper() == "<C-V>"
        or m == "\22"
end

--- @class LineRange
--- @field lstart integer
--- @field lend integer

--- @return LineRange
local function line_range()
    local mode = vim.fn.mode()
    local pos1 = nil
    local pos2 = nil
    if is_visual_mode(mode) then
        vim.cmd([[execute "normal! \<ESC>"]])
        pos1 = vim.fn.getpos("'<")[2]
        pos2 = vim.fn.getpos("'>")[2]
    else
        pos1 = vim.fn.getcurpos()[2]
        pos2 = pos1
    end
    local lstart = math.min(pos1, pos2)
    local lend = math.max(pos1, pos2)
    return { lstart = lstart, lend = lend }
end

--- @type table<string, function>
local M = {
    relative_path = relative_path,
    line_range = line_range,
}

return M
