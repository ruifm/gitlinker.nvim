local Separator = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0) and "\\"
  or "/"
local LogFilePath = vim.fn.stdpath("data") .. Separator .. "gitlinker.log"
local EchoHl = {
  ["ERROR"] = "ErrorMsg",
  ["WARN"] = "ErrorMsg",
  ["INFO"] = "None",
  ["DEBUG"] = "Comment",
}
local Defaults = {
  level = "INFO",
  console = true,
  file = false,
}
local Config = {}

local function setup(option)
  Config = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), option or {})
  assert(type(Config.level) == "string" and EchoHl[Config.level] ~= nil)
end

local function log(level, msg)
  if vim.log.levels[level] < vim.log.levels[Config.level] then
    return
  end

  local msg_lines = vim.split(msg, "\n")
  if Config.console then
    vim.cmd("echohl " .. EchoHl[level])
    for _, line in ipairs(msg_lines) do
      vim.cmd(
        string.format('echom "[gitlinker.nvim] %s"', vim.fn.escape(line, '"'))
      )
    end
    vim.cmd("echohl None")
  end
  if Config.file then
    local fp = io.open(LogFilePath, "a")
    if fp then
      for _, line in ipairs(msg_lines) do
        fp:write(
          string.format(
            "[gitlinker.nvim] %s [%s] - %s\n",
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

local M = {
  setup = setup,
  debug = debug,
  info = info,
  warn = warn,
  error = error,
}

return M
