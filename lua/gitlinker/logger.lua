-- see: `lua print(vim.inspect(vim.log.levels))`
local LogLevels = {
  TRACE = 0,
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
  OFF = 5,
}

local LogLevelNames = {
  [0] = "TRACE",
  [1] = "DEBUG",
  [2] = "INFO",
  [3] = "WARN",
  [4] = "ERROR",
  [5] = "OFF",
}

local LogHighlights = {
  [1] = "Comment",
  [2] = "None",
  [3] = "WarningMsg",
  [4] = "ErrorMsg",
}

local PathSeperator = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
    and "\\"
  or "/"

local Configs = {
  level = LogLevels.INFO,
  console_log = true,
  file_log = false,
  file_log_dir = vim.fn.stdpath("data"),
  file_log_name = "gitlinker.log",
  _file_log_path = string.format(
    "%s%s%s",
    vim.fn.stdpath("data"),
    PathSeperator,
    "gitlinker.log"
  ),
}

--- @param opts gitlinker.Options?
local function setup(opts)
  Configs = vim.tbl_deep_extend("force", vim.deepcopy(Configs), opts or {})
  if type(Configs.level) == "string" then
    Configs.level = LogLevels[Configs.level]
  end

  if Configs.file_log then
    Configs._file_log_path = string.format(
      "%s%s%s",
      Configs.file_log_dir,
      (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0) and "\\" or "/",
      Configs.file_log_name
    )
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
  if Configs.console_log and level >= LogLevels.INFO then
    local msg_chunks = {}
    -- local prefix = ""
    -- if level == LogLevels.ERROR then
    --     prefix = "error! "
    -- elseif level == LogLevels.WARN then
    --     prefix = "warning! "
    -- end
    for _, line in ipairs(msg_lines) do
      table.insert(msg_chunks, {
        string.format("[gitlinker] %s", --[[prefix,]] line),
        LogHighlights[level],
      })
    end
    vim.api.nvim_echo(msg_chunks, false, {})
  end
  if Configs.file_log then
    local fp = io.open(Configs._file_log_path, "a")
    if fp then
      for _, line in ipairs(msg_lines) do
        fp:write(
          string.format(
            "%s [%s]: %s\n",
            os.date("%Y-%m-%d %H:%M:%S"),
            LogLevelNames[level],
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

local function throw(fmt, ...)
  log(LogLevels.ERROR, string.format(fmt, ...))
  error(string.format(fmt, ...))
end

local function ensure(cond, fmt, ...)
  if not cond then
    throw(fmt, ...)
  end
end

local M = {
  setup = setup,
  debug = debug,
  info = info,
  warn = warn,
  err = err,
  throw = throw,
  ensure = ensure,
}

return M
