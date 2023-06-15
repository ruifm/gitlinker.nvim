local job = require("plenary.job")
local util = require("gitlinker.util")

-- copy url to clipboard
--- @param url string
--- @return nil
local function clipboard(url)
  vim.api.nvim_command("let @+ = '" .. url .. "'")
end

-- open url in browser
-- see: https://github.com/axieax/urlview.nvim/blob/b183133fd25caa6dd98b415e0f62e51e061cd522/lua/urlview/actions.lua#L38
--- @param url string
--- @return nil
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
  --- @overload fun(url:string):nil
  clipboard = clipboard,
  --- @overload fun(url:string):nil
  system = system,
}

return M
