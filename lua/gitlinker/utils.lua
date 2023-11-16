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
  for i = start, #s do
    local match = true
    for j = 1, #t do
      if i + j - 1 > #s then
        match = false
        break
      end
      local a = string.byte(s, i + j - 1)
      local b = string.byte(t, j)
      if a ~= b then
        match = false
        break
      end
    end
    if match then
      return i
    end
  end
  return nil
end

--- @param filename string
--- @param opts {trim:boolean?}|nil
--- @return string?
local function readfile(filename, opts)
  opts = opts or { trim = true }
  opts.trim = opts.trim == nil and true or opts.trim

  local f = io.open(filename, "r")
  if f == nil then
    return nil
  end
  local content = vim.trim(f:read("*a"))
  f:close()
  return content
end

--- @param filename string
--- @return string[]?
local function readlines(filename)
  local results = {}
  for line in io.lines(filename) do
    table.insert(results, line)
  end
  return results
end

local M = {
  string_startswith = string_startswith,
  string_endswith = string_endswith,
  string_find = string_find,
  readfile = readfile,
  readlines = readlines,
}

return M
