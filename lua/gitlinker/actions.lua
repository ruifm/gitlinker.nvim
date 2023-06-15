local job = require("plenary.job")
--- @type table<string, any>
local util = require("gitlinker.util")

-- Copy url to clipboard
--- @param url string
local function clipboard(url)
  vim.api.nvim_command("let @+ = '" .. url .. "'")
end

-- Open url in browser
-- Use urlview.nvim's system implementation.
-- See: https://github.com/axieax/urlview.nvim/blob/b183133fd25caa6dd98b415e0f62e51e061cd522/lua/urlview/actions.lua#L38
--- @param url string
local function system(url)
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

--- @type table<string, function>
local M = {
  clipboard = clipboard,
  system = system,
}

return M
