local ECHO_HL = {
  ["ERROR"] = "ErrorMsg",
  ["WARN"] = "ErrorMsg",
  ["INFO"] = "None",
  ["DEBUG"] = "Comment",
}
local LOG_LEVEL = "INFO"
local USE_CONSOLE = nil
local USE_FILE = nil
local FILENAME = nil

local function setup(debug, console_log, file_log, file_log_name)
  if debug then
    LOG_LEVEL = "DEBUG"
  end
  USE_CONSOLE = console_log
  USE_FILE = file_log
  FILENAME = string.format("%s/%s", vim.fn.stdpath("data"), file_log_name)
end

local function log(level, msg)
  if vim.log.levels[level] < vim.log.levels[LOG_LEVEL] then
    return
  end

  local splited_msg = vim.split(msg, "\n")
  if USE_CONSOLE then
    vim.cmd("echohl " .. ECHO_HL[level])
    for _, m in ipairs(splited_msg) do
      vim.cmd(
        string.format(
          'echom "%s"',
          vim.fn.escape(string.format("[gitlinker] %s", m), '"')
        )
      )
    end
    vim.cmd("echohl None")
  end
  if USE_FILE then
    local fp = io.open(FILENAME, "a")
    for _, m in ipairs(splited_msg) do
      fp:write(
        string.format(
          "[gitlinker] %s [%s]: %s\n",
          os.date("%Y-%m-%d %H:%M:%S"),
          level,
          m
        )
      )
    end
    fp:close()
  end
end

local function debug(fmt, ...)
  log("DEBUG", string.format(fmt, ...))
end

local function info(fmt, ...)
  log("INFO", string.format(fmt, ...))
end

local function warn(fmt, ...)
  log("WARN", string.format(fmt, ...))
end

local function error(fmt, ...)
  log("ERROR", string.format(fmt, ...))
end

local function inspect(value)
  if type(value) == "table" then
    local builder = {}
    for i, v in ipairs(value) do
      table.insert(builder, string.format("[%d] = %s", i, inspect(v)))
    end
    for k, v in pairs(value) do
      table.insert(builder, string.format("[%s] = %s", inspect(k), inspect(v)))
    end
    return string.format("{ %s }", table.concat(builder, ", "))
  end
  return tostring(value)
end

local M = {
  setup = setup,
  debug = debug,
  info = info,
  warn = warn,
  error = error,
  inspect = inspect,
}

return M
