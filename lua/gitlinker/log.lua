local M = {}

local log_level = vim.log.levels.ERROR

function M.setup(debug)
  if debug then
    log_level = vim.log.levels.DEBUG
  end
end

local function log(level, msg)
  if level < log_level then
    return
  end
  vim.notify(msg, level)
end

function M.debug(fmt, ...)
  log(vim.log.levels.DEBUG, string.format(fmt, unpack(arg)))
end

function M.info(fmt, ...)
  log(vim.log.levels.INFO, string.format(fmt, unpack(arg)))
end

function M.warn(fmt, ...)
  log(vim.log.levels.WARN, string.format(fmt, unpack(arg)))
end

function M.error(fmt, ...)
  log(vim.log.levels.ERROR, string.format(fmt, unpack(arg)))
end

return M
