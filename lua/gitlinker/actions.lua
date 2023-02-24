local job = require("plenary.job")
local util = require("gitlinker.util")

-- Copy url to clipboard
--
-- @param url the url string
local function copy_to_clipboard(url)
  vim.api.nvim_command("let @+ = '" .. url .. "'")
end

-- Open url in browser
-- Use urlview.nvim's system implementation.
-- Please check: https://github.com/axieax/urlview.nvim/blob/main/lua/urlview/actions.lua#L38
--
-- @param url the url string
local function open_in_browser(url)
  local j
  if util.is_macos() then
    j = job:new({ command = "open", args = { url } })
  elseif util.is_windows() then
    j = job:new({ command = "cmd", args = { "/C", "start", url } })
  else
    j = job:new({ command = "xdg-open", args = { url } })
  end
  j:start()
end

local M = {
  copy_to_clipboard = copy_to_clipboard,
  open_in_browser = open_in_browser,
}

return M
