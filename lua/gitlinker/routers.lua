local utils = require("gitlinker.utils")
local range = require("gitlinker.range")

--- @param lk Linker
--- @return string
local function blob(lk)
  local builder = ""
  builder = builder .. lk.protocol == "git" and "https://"
    or (lk.protocol .. "://")
  builder = builder .. lk.host .. "/"
  builder = builder .. lk.user .. "/"
  builder = builder
    .. (utils.string_endswith(lk.repo, ".git") and lk.repo:sub(1, #lk.repo - 4) or lk.repo)
    .. "/"
  builder = builder .. "blob/"
  builder = builder .. lk.rev .. "/"
  builder = builder
    .. lk.file
    .. (
      utils.string_endswith(lk.file, ".md", { ignorecase = true })
        and "?plain=1"
      or ""
    )
  local r = range.stringify({ lstart = lk.lstart, lend = lk.lend })
  if r then
    builder = builder .. r
  end
  return builder
end

local M = {
  blob = blob,
}

return M
