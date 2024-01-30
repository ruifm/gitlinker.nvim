local M = {}

local job = require("plenary.job")

--- copies the url to clipboard
--
-- @param url the url string
function M.copy_to_clipboard(url)
  vim.fn.setreg("+", url)
end

--- opens the url in your default browser
--- In NeoVim nightly, this can be replaced with `:h vim.ui.open()`
--
-- Uses xdg-open
-- @param url the url string
function M.open_in_browser(url)
  local command = vim.loop.os_uname().sysname == "Darwin" and "open"
    or "xdg-open"
  job:new({ command = command, args = { url } }):start()
end

return M
