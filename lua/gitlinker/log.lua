local M = {}

local echohl = {
  ["ERROR"] = "ErrorMsg",
  ["WARN"] = "ErrorMsg",
  ["INFO"] = "None",
  ["DEBUG"] = "Comment",
}
local log_level = "INFO"
local use_console = nil
local use_file = nil
local filename = nil

function M.setup(opts)
  if opts.debug then
    log_level = "DEBUG"
  end
  use_console = opts.console_log
  use_file = opts.file_log
  filename = string.format("%s/%s", vim.fn.stdpath("data"), opts.file_log_name)
end

local function log(level, msg)
  if vim.log.levels[level] < vim.log.levels[log_level] then
    return
  end

  local split_msg = vim.split(msg, "\n")
  if use_console then
    vim.cmd("echohl " .. echohl[level])
    for _, m in ipairs(split_msg) do
      vim.cmd(
        string.format(
          'echom "%s"',
          vim.fn.escape(string.format("[gitlinker] %s", m), '"')
        )
      )
    end
    vim.cmd("echohl None")
  end
  if use_file then
    local fp = io.open(filename, "a")
    for _, m in ipairs(split_msg) do
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

function M.debug(fmt, ...)
  log("DEBUG", string.format(fmt, ...))
end

function M.info(fmt, ...)
  log("INFO", string.format(fmt, ...))
end

function M.warn(fmt, ...)
  log("WARN", string.format(fmt, ...))
end

function M.error(fmt, ...)
  log("ERROR", string.format(fmt, ...))
end

return M
