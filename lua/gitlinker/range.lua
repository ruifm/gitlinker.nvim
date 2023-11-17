local logger = require("gitlinker.logger")

--- @param m string
--- @return boolean
local function _is_visual_mode(m)
  return type(m) == "string" and string.upper(m) == "V"
    or string.upper(m) == "CTRL-V"
    or string.upper(m) == "<C-V>"
    or m == "\22"
end

--- @alias gitlinker.Range {lstart:integer,lend:integer,cstart:integer?,cend:integer?}
--- @return gitlinker.Range
local function make_range()
  local m = vim.fn.mode()
  logger.debug("|range.make_range| mode:%s", vim.inspect(m))
  local l1 = nil
  local l2 = nil
  if _is_visual_mode(m) then
    vim.cmd([[execute "normal! \<ESC>"]])
    l1 = vim.fn.getpos("'<")[2]
    l2 = vim.fn.getpos("'>")[2]
  else
    l1 = vim.fn.getcurpos()[2]
    l2 = l1
  end
  local lstart = math.min(l1, l2)
  local lend = math.max(l1, l2)
  local o = {
    lstart = lstart,
    lend = lend,
  }
  return o
end

--- @param r any?
--- @return boolean
local function is_range(r)
  return type(r) == "table"
    and type(r.lstart) == "number"
    and r.lstart >= 0
    and type(r.lend) == "number"
    and r.lend > 0
end

local M = {
  _is_visual_mode = _is_visual_mode,
  is_range = is_range,
  make_range = make_range,
}

return M
