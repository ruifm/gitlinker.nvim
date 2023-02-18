local M = {}

local api = vim.api
local job = require("plenary.job")

--- copies the url to clipboard
--
-- @param url the url string
function M.copy_to_clipboard(url)
  api.nvim_command("let @+ = '" .. url .. "'")
end

--- opens the url in your default browser
--
-- Uses xdg-open
-- @param url the url string
function M.open_in_browser(url)
  local command = "xdg-open"
  local sysname = vim.loop.os_uname().sysname
  if sysname == "Darwin" then
    command = "open"
  elseif
    string.len(sysname) >= 7
    and string.sub(string.lower(sysname), 1, 7) == "windows"
  then
    command = "explorer"
  end
  job:new({ command = command, args = { url } }):start()
end

return M
