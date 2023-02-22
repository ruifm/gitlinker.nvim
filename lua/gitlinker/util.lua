local M = {}

-- \\ to /
function M.to_slash_path(p)
  if p == nil then
    return p
  end
  return string.gsub(p, "\\", "/")
end

-- / to \\
function M.to_backslash_path(p)
  if p == nil then
    return p
  end
  return string.gsub(p, "/", "\\")
end

return M
