local M = {}

function M.normalize_path(p)
  if p == nil then
    return p
  end
  return string.gsub(p, "\\", "/")
end

return M
