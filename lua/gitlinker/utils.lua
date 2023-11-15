--- @param s string
--- @param t string
--- @param opts {ignorecase:boolean?}?
--- @return boolean
local function string_startswith(s, t, opts)
  opts = opts or { ignorecase = false }
  opts.ignorecase = opts.ignorecase or false

  local start_pos = 1
  local end_pos = string.len(t)
  if start_pos > end_pos then
    return false
  end
  if string.len(s) < string.len(t) then
    return false
  end
  return opts.ignorecase and (s:sub(start_pos, end_pos):lower() == t:lower())
    or (s:sub(start_pos, end_pos) == t)
end

--- @param s string
--- @param t string
--- @param opts {ignorecase:boolean?}?
--- @return boolean
local function string_endswith(s, t, opts)
  opts = opts or { ignorecase = false }
  opts.ignorecase = opts.ignorecase or false

  local start_pos = string.len(s) - string.len(t) + 1
  local end_pos = string.len(s)
  if start_pos > end_pos then
    return false
  end
  if string.len(s) < string.len(t) then
    return false
  end
  return opts.ignorecase and (s:sub(start_pos, end_pos):lower() == t:lower())
    or (s:sub(start_pos, end_pos) == t)
end

--- @param s string
--- @param t string
--- @param start integer?
--- @return integer?
local function string_find(s, t, start)
  start = start or 1
  local result = vim.fn.stridx(s, t, start - 1)
  return result >= 0 and (result + 1) or nil
end

local M = {
  string_startswith = string_startswith,
  string_endswith = string_endswith,
  string_find = string_find,
}

return M
