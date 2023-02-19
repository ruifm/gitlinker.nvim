local M = {}

function M.get_base_https_url(url_data)
  local url = "https://" .. url_data.host
  if url_data.port then
    url = url .. ":" .. url_data.port
  end
  return url .. "/" .. url_data.repo
end

--- Constructs a github style url
function M.get_github_type_url(url_data)
  local url = M.get_base_https_url(url_data)
  if not url_data.file or not url_data.rev then
    return url
  end
  url = url .. "/blob/" .. url_data.rev .. "/" .. url_data.file

  if not url_data.lstart then
    return url
  end
  url = url .. "#L" .. url_data.lstart
  if url_data.lend then
    url = url .. "-L" .. url_data.lend
  end
  return url
end

--- Constructs a gitlab style url
function M.get_gitlab_type_url(url_data)
  local url = M.get_base_https_url(url_data)
  if not url_data.file or not url_data.rev then
    return url
  end
  url = url .. "/-/blob/" .. url_data.rev .. "/" .. url_data.file

  if not url_data.lstart then
    return url
  end
  url = url .. "#L" .. url_data.lstart
  if url_data.lend then
    url = url .. "-" .. url_data.lend
  end
  return url
end

--- Constructs a bitbucket style url
function M.get_bitbucket_type_url(url_data)
  local url = M.get_base_https_url(url_data)
  if not url_data.file or not url_data.rev then
    return url
  end
  url = url .. "/src/" .. url_data.rev .. "/" .. url_data.file

  if not url_data.lstart then
    return url
  end
  url = url .. "#lines-" .. url_data.lstart
  if url_data.lend then
    url = url .. ":" .. url_data.lend
  end

  return url
end

--- Gets a matching callback for a given host
--
-- @param target_host the host to get the matching callback from.
-- this can be either a verbatim match or a lua string.match pattern.
--
-- @returns the host's callback
function M.get_matching_callback(target_host)
  local matching_callback
  local callbacks = require("gitlinker.opts").get().callbacks
  for host, callback in pairs(callbacks) do
    if target_host == host or target_host:match(host) then
      matching_callback = callback
      break
    end
  end
  if not matching_callback then
    vim.notify(
      string.format("No host callback defined for host '%s'", target_host),
      vim.log.levels.ERROR
    )
  end
  return matching_callback
end

return M
