local PathSeparator = (vim.fn.has("win32") or vim.fn.has("win64")) and "\\"
  or "/"
local LogFilePath = vim.fn.stdpath("data") .. PathSeparator .. "gitlinker.log"

--- @alias LogLevelType "ERROR"|"WARN"|"INFO"|"DEBUG"

--- @type table<LogLevelType, string>
local EchoHl = {
  ["ERROR"] = "ErrorMsg",
  ["WARN"] = "ErrorMsg",
  ["INFO"] = "None",
  ["DEBUG"] = "Comment",
}
--- @type table<string, any>
local Defaults = {
  --- @type LogLevelType
  level = "INFO",
  console = true,
  file = false,
}
--- @type table<string, any>
local Config = {}

--- @param option table<string, any>
--- @return nil
local function setup(option)
  Config = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), option or {})
  assert(type(Config.level) == "string" and EchoHl[Config.level] ~= nil)
end

--- @param level LogLevelType
--- @param msg string
--- @return nil
local function log(level, msg)
  if vim.log.levels[level] < vim.log.levels[Config.level] then
    return
  end

  local msg_lines = vim.split(msg, "\n")
  if Config.console then
    vim.cmd("echohl " .. EchoHl[level])
    for _, line in ipairs(msg_lines) do
      vim.cmd(string.format('echom "%s"', vim.fn.escape(line, '"')))
    end
    vim.cmd("echohl None")
  end
  if Config.file then
    local fp = io.open(LogFilePath, "a")
    if fp then
      for _, line in ipairs(msg_lines) do
        fp:write(
          string.format(
            "%s [%s] - %s\n",
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

--- @param fmt string
--- @param ... any
--- @return nil
local function debug(fmt, ...)
  log("DEBUG", string.format(fmt, ...))
end

--- @param fmt string
--- @param ... any
--- @return nil
local function info(fmt, ...)
  log("INFO", string.format(fmt, ...))
end

--- @param fmt string
--- @param ... any
--- @return nil
local function warn(fmt, ...)
  log("WARN", string.format(fmt, ...))
end

--- @param fmt string
--- @param ... any
--- @return nil
local function error(fmt, ...)
  log("ERROR", string.format(fmt, ...))
end

--- @type table<string, function>
local M = {
  --- @overload fun(option:table<string, any>):nil
  setup = setup,
  --- @overload fun(fmt:string, ...:any):nil
  debug = debug,
  --- @overload fun(fmt:string, ...:any):nil
  info = info,
  --- @overload fun(fmt:string, ...:any):nil
  warn = warn,
  --- @overload fun(fmt:string, ...:any):nil
  error = error,
}

return M
