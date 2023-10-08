local PATH_SEPERATOR = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
        and "\\"
    or "/"

local LOG_FILE_PATH = vim.fn.stdpath("data")
    .. PATH_SEPERATOR
    .. "gitlinker.log"

-- see: `lua print(vim.inspect(vim.log.levels))`
local LogLevels = {
    TRACE = 0,
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    OFF = 5,
}

local LogHighlights = {
    [1] = "Comment",
    [2] = "None",
    [3] = "WarningMsg",
    [4] = "ErrorMsg",
}

local Defaults = {
    level = LogLevels.INFO,
    console = true,
    file = false,
}

local Configs = {}

--- @param option Configs?
local function setup(option)
    Configs = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), option or {})
    if type(Configs.level) == "string" then
        Configs.level = LogLevels[Configs.level]
    end
    assert(
        type(Configs.level) == "number" and LogHighlights[Configs.level] ~= nil
    )
end

--- @param level integer
--- @param msg string
local function log(level, msg)
    if level < Configs.level then
        return
    end

    local msg_lines = vim.split(msg, "\n", { plain = true })
    if Configs.console then
        local msg_chunks = {}
        local prefix = ""
        if level == LogLevels.ERROR then
            prefix = "error! "
        elseif level == LogLevels.WARN then
            prefix = "warning! "
        end
        for _, line in ipairs(msg_lines) do
            table.insert(msg_chunks, {
                string.format("[gitlinker] %s%s", prefix, line),
                LogHighlights[level],
            })
        end
        vim.api.nvim_echo(msg_chunks, false, {})
    end
    if Configs.file then
        local fp = io.open(LOG_FILE_PATH, "a")
        if fp then
            for _, line in ipairs(msg_lines) do
                fp:write(
                    string.format(
                        "%s [%s]: %s\n",
                        os.date("%Y-%m-%d %H:%M:%S"),
                        level,
                        line
                    )
                )
            end
            fp:close()
        end
    end
end

local function debug(fmt, ...)
    log(LogLevels.DEBUG, string.format(fmt, ...))
end

local function info(fmt, ...)
    log(LogLevels.INFO, string.format(fmt, ...))
end

local function warn(fmt, ...)
    log(LogLevels.WARN, string.format(fmt, ...))
end

local function err(fmt, ...)
    log(LogLevels.ERROR, string.format(fmt, ...))
end

local M = {
    setup = setup,
    debug = debug,
    info = info,
    warn = warn,
    err = err,
}

return M
