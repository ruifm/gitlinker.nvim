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
  vim.api.nvim_command("echohl " .. echohl[level])
  for _, m in ipairs(split_msg) do
    vim.api.nvim_command(string.format('echom "%s"', vim.fn.escape(m, '"')))
  end
  vim.api.nvim_command("echohl None")
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
