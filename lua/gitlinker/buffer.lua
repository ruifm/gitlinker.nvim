local M = {}

local api = vim.api
local path = require("plenary.path")

function M.get_relative_path(cwd)
  return path:new(api.nvim_buf_get_name(0)):make_relative(cwd)
end

function M.get_curr_line()
  return api.nvim_win_get_cursor(0)[1]
end

function M.get_range(mode, add_current_line_on_normal_mode)
  local lstart
  local lend
  if mode == "v" then
    lstart = api.nvim_buf_get_mark(0, "<")[1]
    lend = api.nvim_buf_get_mark(0, ">")[1]
  elseif add_current_line_on_normal_mode == true then
    lstart = M.get_curr_line()
  end

  return { lstart = lstart, lend = lend }
end

return M
