local M = {}

local api = vim.api
local job = require 'plenary.job'

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
    job:new({command = "xdg-open", args = {url}}):start()
end

return M
