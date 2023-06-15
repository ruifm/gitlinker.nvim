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
  --- @type boolean
  console = true,
  --- @type string
  name = "gitlinker",
  --- @type boolean
  file = false,
  --- @type string
  file_name = "gitlinker.log",
  --- @type string
  file_dir = vim.fn.stdpath("data"),
  --- @type string|nil
  file_path = nil,
}
--- @type table<string, any>
local Config = {}
--- @type string
local PathSeparator = (vim.fn.has("win32") or vim.fn.has("win64")) and "\\"
  or "/"

--- @param option table<string, any>
--- @return nil
local function setup(option)
  Config = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), option or {})
  assert(type(Config.level) == "string" and EchoHl[Config.level] ~= nil)
  if Config.file_name and string.len(Config.file_name) > 0 then
    -- For Windows: $env:USERPROFILE\AppData\Local\nvim-data\lsp-progress.log
    -- For *NIX: ~/.local/share/nvim/lsp-progress.log
    if Config.file_dir and string.len(Config.file_dir) then
      Config.file_path = string.format(
        "%s%s%s",
        Config.file_dir,
        PathSeparator,
        Config.file_name
      )
    else
      Config.file_path = Config.file_name
    end
  end
  if Config.file then
    assert(
      type(Config.file_path) == "string" and string.len(Config.file_path) > 0
    )
  end
end

--- @param level "ERROR"|"WARN"|"INFO"|"DEBUG"
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
      vim.cmd(
        string.format(
          'echom "%s"',
          vim.fn.escape(string.format("%s: %s", Config.name, line), '"')
        )
      )
    end
    vim.cmd("echohl None")
  end
  if Config.file then
    local fp = io.open(Config.file_path, "a")
    if fp then
      for _, line in ipairs(msg_lines) do
        fp:write(
          string.format(
            "%s: %s [%s] - %s\n",
            Config.name,
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
  --- @overload fun(option:table<string,any>):nil
  setup = setup,
  --- @overload fun(fmt:string,...:any):nil
  debug = debug,
  --- @overload fun(fmt:string,...:any):nil
  info = info,
  --- @overload fun(fmt:string,...:any):nil
  warn = warn,
  --- @overload fun(fmt:string,...:any):nil
  error = error,
}

return M
