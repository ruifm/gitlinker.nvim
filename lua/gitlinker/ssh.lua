local M = {}

local job = require("plenary.job")

-- wrap the ssh command to do the right thing always
local function ssh(args)
  local output
  local p = job:new({
    command = "ssh",
    args = args,
  })
  p:after_success(function(j)
    output = j:result()
  end)
  p:sync()
  return output or {}
end

local function as_table(data)
  local result = {}
  for _, line in ipairs(data) do
    for key, value in string.gmatch(line, "(%w+)%s+(.*)") do
      result[key] = value
    end
  end
  return result
end

local function get_configuration(alias)
  local configuration = ssh({ "-G", alias })
  return as_table(configuration)
end

local function get_hostname(alias)
  return get_configuration(alias)["hostname"]
end

--- Fixes aliased remote uri using the hostname set in ssh config.
-- In some cases, the user can create an alias for a given user/hostname.
-- So this function replaces the aliased name with the hostname set in ssh
-- config.
-- @params uri Remote uri from which alias will be replaced
-- @return uri with replaced alias or nil
function M.fix_hostname(uri)
  local alias = string.match(uri, "([^:]+):.*")
  local hostname = get_hostname(alias)

  if alias == hostname then
    return nil
  end

  return string.gsub(uri, alias, hostname)
end

return M
