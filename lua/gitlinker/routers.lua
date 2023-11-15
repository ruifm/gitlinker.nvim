local utils = require("gitlinker.utils")
local range = require("gitlinker.range")
-- local logger = require("gitlinker.logger")

--- @class gitlinker.Builder
--- @field protocol string?
--- @field host string?
--- @field user string?
--- @field repo string?
--- @field rev string?
--- @field file string?
--- @field range string?
local Builder = {}

--- @param r gitlinker.Range?
--- @return string?
local function LC_range(r)
  if not range.is_range(r) then
    return nil
  end
  assert(r ~= nil)
  local tmp = string.format([[#L%d]], r.lstart)
  if type(r.lend) == "number" and r.lend > r.lstart then
    tmp = tmp .. string.format([[-L%d]], r.lend)
  end
  return tmp
end

--- @param r gitlinker.Range?
--- @return string?
local function lines_range(r)
  if not range.is_range(r) then
    return nil
  end
  assert(r ~= nil)
  local tmp = string.format([[#lines-%d]], r.lstart)
  if type(r.lend) == "number" and r.lend > r.lstart then
    tmp = tmp .. string.format([[:%d]], r.lend)
  end
  return tmp
end

--- @param lk gitlinker.Linker
--- @param range_maker fun(r:gitlinker.Range?):string?|nil
--- @return gitlinker.Builder
function Builder:new(lk, range_maker)
  range_maker = range_maker or LC_range
  local r = range_maker({ lstart = lk.lstart, lend = lk.lend })
  local o = {
    protocol = lk.protocol == "git" and "https://" or (lk.protocol .. "://"),
    host = lk.host .. "/",
    user = lk.user .. "/",
    repo = (utils.string_endswith(lk.repo, ".git") and lk.repo:sub(
      1,
      #lk.repo - 4
    ) or lk.repo) .. "/",
    rev = lk.rev .. "/",
    file = lk.file .. (utils.string_endswith(
      lk.file,
      ".md",
      { ignorecase = true }
    ) and "?plain=1" or ""),
    range = type(r) == "string" and r or "",
  }
  setmetatable(o, self)
  self.__index = self

  return o
end

--- @param url "blob"|"blame"|"src"
--- @return string
function Builder:build(url)
  return table.concat({
    self.protocol,
    self.host,
    self.user,
    self.repo,
    url .. "/",
    self.rev,
    self.file,
    self.range,
  }, "")
end

--- @param lk gitlinker.Linker
--- @return string
local function blob(lk)
  -- logger.debug("|routers.blob|lk:%s", vim.inspect(lk))
  local builder = Builder:new(lk)
  -- logger.debug("|routers.blob|builder:%s", vim.inspect(builder))
  return builder:build("blob")
end

--- @param lk gitlinker.Linker
--- @return string
local function src(lk)
  local builder = Builder:new(lk, lines_range)
  return builder:build("src")
end

--- @param lk gitlinker.Linker
--- @return string
local function blame(lk)
  local builder = Builder:new(lk)
  return builder:build("blame")
end

local M = {
  -- Builder
  Builder = Builder,

  -- routers
  blob = blob,
  blame = blame,
  src = src,

  -- line ranges
  LC_range = LC_range,
  lines_range = lines_range,
}

return M
