local M = {}

local api = vim.api
local path = require("plenary.path")
local log = require("gitlinker.log")

function M.get_relative_path(cwd)
  local buf_path = path:new(api.nvim_buf_get_name(0))
  local relative_path = buf_path:make_relative(cwd)
  log.debug(
    "buf_path:%s, cwd:%s, relative_path:%s",
    vim.inspect(buf_path),
    vim.inspect(cwd),
    vim.inspect(relative_path)
  )
  return relative_path
end

function M.get_curr_line()
  return api.nvim_win_get_cursor(0)[1]
end

function M.get_range(mode, add_current_line_on_normal_mode)
  local lstart
  local lend
  if mode == "v" then
    local pos1 = vim.fn.getpos("v")[2]
    local pos2 = vim.fn.getcurpos()[2]
    lstart = math.min(pos1, pos2)
    lend = math.max(pos1, pos2)
  elseif add_current_line_on_normal_mode == true then
    lstart = M.get_curr_line()
  end

  return { lstart = lstart, lend = lend }
end

return M
