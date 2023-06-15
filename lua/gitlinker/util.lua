local path = require("plenary.path")
local logger = require("gitlinker.logger")

--- @return boolean
local function is_macos()
  return vim.loop.os_uname().sysname == "Darwin"
end

--- @return boolean
local function is_windows()
  return vim.fn.has("win32") or vim.fn.has("win64")
end

--- @param cwd string|nil
--- @return string
local function relative_path(cwd)
  -- In Windows, path separator is '\\'
  -- But git root command will give us path with '/' separator
  -- This will lead us to the wrong relative path because plenary.path don't recoginize them
  -- So here we replace '/' to '\\' for plenary.path
  logger.debug("[util.get_relative_path] cwd:%s", vim.inspect(cwd))
  if cwd ~= nil and is_windows() then
    if cwd:find("/") then
      cwd = cwd:gsub("/", "\\")
    end
  end

  local buf_path = path:new(vim.api.nvim_buf_get_name(0))
  local relpath = buf_path:make_relative(cwd)
  logger.debug(
    "[util.get_relative_path] buf_path:%s, cwd:%s, relpath:%s",
    vim.inspect(buf_path),
    vim.inspect(cwd),
    vim.inspect(relpath)
  )

  -- Then we translate '\\' back to '/'
  if relpath ~= nil and is_windows() then
    if relpath:find("\\") then
      relpath = relpath:gsub("\\", "/")
    end
  end
  return relpath
end

--- @class LineRange
--- @field lstart integer
--- @field lend integer
local LineRange = {}

--- @return LineRange
local function line_range()
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
  return { lstart = lstart, lend = lend }
end

--- @type table<string, function>
local M = {
  --- @overload fun():boolean
  is_macos = is_macos,
  --- @overload fun():boolean
  is_windows = is_windows,
  --- @overload fun(cwd:string|nil):string
  relative_path = relative_path,
  --- @overload fun():LineRange
  line_range = line_range,
}

return M
