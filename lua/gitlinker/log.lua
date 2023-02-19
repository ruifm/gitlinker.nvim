local M = {}

local echohl = {
  ["ERROR"] = "ErrorMsg",
  ["WARN"] = "ErrorMsg",
  ["INFO"] = "None",
  ["DEBUG"] = "Comment",
}
local log_level = "ERROR"

function M.setup(debug)
  if debug then
    log_level = "DEBUG"
  end
end

local function log(level, msg)
  if vim.log.levels[level] < vim.log.levels[log_level] then
    return
  end
  local split_msg = vim.split(msg, "\n")
  vim.fn.echohl(echohl[level])
  for _, m in ipairs(split_msg) do
    vim.fn.echo(vim.fn.escape(m, '"'))
  end
  vim.fn.echohl("None")
end

function M.debug(msg)
  log("DEBUG", msg)
end

function M.info(msg)
  log("INFO", msg)
end

function M.warn(msg)
  log("WARN", msg)
end

function M.error(msg)
  log("ERROR", msg)
end

return M
