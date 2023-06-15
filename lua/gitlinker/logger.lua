local EchoHl = {
  ["ERROR"] = "ErrorMsg",
  ["WARN"] = "ErrorMsg",
  ["INFO"] = "None",
  ["DEBUG"] = "Comment",
}
local Defaults = {
  level = "INFO",
  console = true,
  name = "gitlinker",
  file = false,
  file_name = "gitlinker.log",
  file_dir = vim.fn.stdpath("data"),
  file_path = nil,
}
local Config = {}
local PathSeparator = vim.loop.os_uname().sysname:match("Windows") and "\\"
  or "/"

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
