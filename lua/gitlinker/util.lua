local path = require("plenary.path")
local log = require("gitlinker.log")
local util = require("gitlinker.util")

-- \\ to /
local function to_slash_path(p)
  if p == nil then
    return p
  end
  return string.gsub(p, "\\", "/")
end

-- / to \\
local function to_backslash_path(p)
  if p == nil then
    return p
  end
  return string.gsub(p, "/", "\\")
end

local function relative_path(cwd)
  local buf_path = path:new(vim.api.nvim_buf_get_name(0))
  if cwd ~= nil then
    cwd = to_backslash_path(cwd)
  end
  local relative_path = buf_path:make_relative(cwd)
  log.debug(
    "[buffer.get_relative_path] buf_path:%s, cwd:%s, relative_path:%s",
    vim.inspect(buf_path),
    vim.inspect(cwd),
    vim.inspect(relative_path)
  )
  return relative_path
end

local function cursor_line_number()
  return vim.api.nvim_win_get_cursor(0)[1]
end

local function selected_line_range(mode, add_current_line_on_normal_mode)
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

local M = {
  to_slash_path = to_slash_path,
  to_backslash_path = to_backslash_path,
  relative_path = relative_path,
  cursor_line_number = cursor_line_number,
  selected_line_range = selected_line_range,
}

return M
