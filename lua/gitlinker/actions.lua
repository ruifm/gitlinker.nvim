local M = {}

local api = vim.api
local fn = vim.fn

--- copies the url to clipboard
--
-- @param url the url string
function M.copy_to_clipboard(url)
  api.nvim_command("let @+ = '" .. url .. "'")
end

--- opens the url in your default browser
--
-- @param url the url string
function M.open_in_browser(url)
  fn.jobstart(
    { require("gitlinker.opts").get().open_cmd, url },
    { detach = true }
  )
end

return M
