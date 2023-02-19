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

function M.debug(msg)
  log(vim.log.levels.DEBUG, msg)
end

function M.info(msg)
  log(vim.log.levels.INFO, msg)
end

function M.warn(msg)
  log(vim.log.levels.WARN, msg)
end

function M.error(msg)
  log(vim.log.levels.error, msg)
end

return M
