local logger = require("gitlinker.logger")

-- normalize path slash from '\\' to '/'
--- @param p string
--- @return string
local function path_normalize(p)
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
local function path_relative(cwd)
    cwd = cwd or vim.fn.getcwd()
    cwd = vim.fn.resolve(cwd)
    cwd = path_normalize(cwd)

    local bufpath = vim.api.nvim_buf_get_name(0)
    bufpath = vim.fn.resolve(bufpath)
    bufpath = path_normalize(bufpath)

    logger.debug(
        "|util.path_relative| enter, cwd:%s, bufpath:%s",
        vim.inspect(cwd),
        vim.inspect(bufpath)
    )

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
    logger.debug("|util.path_relative| result:%s", vim.inspect(result))
    return result
end

--- @param m string
--- @return boolean
local function is_visual_mode(m)
    return type(m) == "string" and string.upper(m) == "V"
        or string.upper(m) == "CTRL-V"
        or string.upper(m) == "<C-V>"
        or m == "\22"
end

--- @return {lstart:integer,lend:integer}
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

local M = {
    path_normalize = path_normalize,
    path_relative = path_relative,
    is_visual_mode = is_visual_mode,
    line_range = line_range,
}

return M
