local path = require("plenary.path")
local log = require("gitlinker.log")

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
  local relpath = buf_path:make_relative(cwd)
  log.debug(
    "[util.get_relative_path] buf_path:%s, cwd:%s, relpath:%s",
    vim.inspect(buf_path),
    vim.inspect(cwd),
    vim.inspect(relpath)
  )
  return relpath
end

local function selected_line_range()
  -- local lstart
  -- local lend
  -- local mode = vim.api.nvim_get_mode().mode
  -- if mode:lower() == "v" or mode:lower() == "x" then
  local pos1 = vim.fn.getpos("v")[2]
  local pos2 = vim.fn.getcurpos()[2]
  local lstart = math.min(pos1, pos2)
  local lend = math.max(pos1, pos2)
  --   log.debug(
  --     "[util.selected_line_range] mode:%s, pos1:%d, pos2:%d",
  --     mode,
  --     pos1,
  --     pos2
  --   )
  -- else
  --   lstart = vim.api.nvim_win_get_cursor(0)[1]
  --   log.debug("[util.selected_line_range] mode:%s, lstart:%d", mode, lstart)
  -- end
  --
  return { lstart = lstart, lend = lend }
end

local M = {
  to_slash_path = to_slash_path,
  to_backslash_path = to_backslash_path,
  relative_path = relative_path,
  selected_line_range = selected_line_range,
}

return M
