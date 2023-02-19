local M = {}

local pjob = require("plenary.job")
local os = vim.loop.os_uname().sysname

-- Copy url to clipboard
--
-- @param url the url string
function M.copy_to_clipboard(url)
  vim.api.nvim_command("let @+ = '" .. url .. "'")
end

-- Open url in browser
--
-- Use urlview.nvim's system implementation.
-- Please check: https://github.com/axieax/urlview.nvim/blob/main/lua/urlview/actions.lua#L38
--
-- @param url the url string
function M.open_in_browser(url)
  local j
  if os == "Darwin" then
    j = pjob:new({ command = "open", args = { url } })
  elseif os:match("Windows") then
    j = pjob:new({ command = "cmd", args = { "/C", "start", url } })
  else
    j = pjob:new({ command = "xdg-open", args = { url } })
  end
  j:start()
end

return M
