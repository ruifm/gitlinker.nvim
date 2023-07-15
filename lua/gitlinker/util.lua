local path = require("plenary.path")
local logger = require("gitlinker.logger")
local os = vim.loop.os_uname().sysname

--- @return boolean
local function is_macos()
  return vim.fn.has("mac") > 0
end

--- @return boolean
local function is_windows()
  return vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0
end

--- @param cwd string|nil
--- @return string
local function relative_path(cwd)
  -- In Windows, path separator is '\\'
  -- But git root command will give us path with '/' separator
  -- This will lead us to the wrong relative path because plenary.path don't recoginize them
  -- So here we replace '/' to '\\' for plenary.path

  logger.debug(
    "|util.relative_path| cwd1(%s):%s",
    vim.inspect(type(cwd)),
    vim.inspect(cwd)
  )

  local buf_path = path:new(vim.api.nvim_buf_get_name(0))
  local relpath = nil

  if is_windows() and cwd ~= nil then
    local buf_path_filename = tostring(buf_path)
    if buf_path_filename:sub(1, #cwd) == cwd then
      relpath = buf_path_filename:sub(#cwd + 1, -1)
      logger.debug(
        "|util.relative_path| relpath1(%s):%s",
        vim.inspect(type(relpath)),
        vim.inspect(relpath)
      )
      if relpath:sub(1, 1) == "/" or relpath:sub(1, 1) == "\\" then
        relpath = relpath:sub(2, -1)
        logger.debug(
          "|util.relative_path| relpath1.1(%s):%s",
          vim.inspect(type(relpath)),
          vim.inspect(relpath)
        )
      end
    else
      relpath = buf_path:make_relative(cwd)
    end
  else
    relpath = buf_path:make_relative(cwd)
  end

  logger.debug(
    "|util.relative_path| buf_path(%s):%s, relpath(%s):%s",
    vim.inspect(type(buf_path)),
    vim.inspect(buf_path),
    vim.inspect(type(relpath)),
    vim.inspect(relpath)
  )

  -- Then we translate '\\' back to '/'
  -- if relpath ~= nil and is_windows() then
  --   if relpath:find("\\") then
  --     relpath = relpath:gsub("\\", "/")
  --   end
  -- end
  logger.debug(
    "|util.relative_path| relpath2(%s):%s",
    vim.inspect(type(relpath)),
    vim.inspect(relpath)
  )
  return relpath
end

local function is_visual_mode(m)
  return type(m) == "string" and m:upper() == "V"
    or m:upper() == "CTRL-V"
    or m:upper() == "<C-V>"
    or m == "\22"
end

--- @class LineRange
--- @field lstart integer
--- @field lend integer

--- @return LineRange
local function line_range()
  vim.cmd([[execute "normal! \<ESC>"]])
  local mode = vim.fn.visualmode()
  local pos1 = nil
  local pos2 = nil
  if is_visual_mode(mode) then
    pos1 = vim.fn.getpos("'<")[2]
    pos2 = vim.fn.getpos("'>")[2]
  else
    pos1 = vim.fn.getpos("v")[2]
    -- if mode == "v" then
    --   pos2 = vim.fn.getpos(".")[2]
    -- else
    pos2 = vim.fn.getcurpos()[2]
    -- end
  end
  local lstart = math.min(pos1, pos2)
  local lend = math.max(pos1, pos2)
  return { lstart = lstart, lend = lend }
end

--- @type table<string, function>
local M = {
  is_macos = is_macos,
  is_windows = is_windows,
  relative_path = relative_path,
  line_range = line_range,
}

return M
