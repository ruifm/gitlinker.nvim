local M = {}

--- Constructs a github style url
--
-- @param url_data table containing
-- {
--  host = "<hostname>", -- e.g. github.com
--  repo = "<repo-path>", -- e.g. ruifm/gitlinker.nvim
--  rev = "revision-sha", -- the commit revision sha
--  file = "<filepath>", the file path
--  lstart = <number>/nil, the line starting range
--  lend = <number>/nil, the line ending range
-- }
--
-- @returns The url string
function M.get_github_type_url(url_data)
    local url = "https://" .. url_data.host .. "/" .. url_data.repo .. "/blob/" ..
                    url_data.rev .. "/" .. url_data.file
    if url_data.lstart then
        url = url .. "#L" .. url_data.lstart
        if url_data.lend then url = url .. "-L" .. url_data.lend end
    end
    return url
end

--- Constructs a gitea style url
--
-- @param url_data table containing
-- {
--  host = "<hostname>", -- e.g. gitea.com
--  repo = "<repo-path>", -- e.g. ruifm/gitlinker.nvim
--  rev = "revision-sha", -- the commit revision sha
--  file = "<filepath>", the file path
--  lstart = <number>/nil, the line starting range
--  lend = <number>/nil, the line ending range
-- }
--
-- @returns The url string
function M.get_gitea_type_url(url_data)
    local url = "https://" .. url_data.host .. "/" .. url_data.repo .. "/src/commit/" ..
                    url_data.rev .. "/" .. url_data.file
    if url_data.lstart then
        url = url .. "#L" .. url_data.lstart
        if url_data.lend then url = url .. "-L" .. url_data.lend end
    end
    return url
end

--- Constructs a gitlab style url
--
-- @param url_data table containing
-- {
--  host = "<hostname>", -- e.g. gitlab.com
--  repo = "<repo-path>", -- e.g. ruifm/gitlinker.nvim
--  rev = "revision-sha", -- the commit revision sha
--  file = "<filepath>", the file path
--  lstart = <number>/nil, the line starting range
--  lend = <number>/nil, the line ending range
-- }
--
-- @returns The url string
function M.get_gitlab_type_url(url_data)
    local url = "https://" .. url_data.host .. "/" .. url_data.repo .. "-/blob/" ..
                    url_data.rev .. "/" .. url_data.file
    if url_data.lstart then
        url = url .. "#L" .. url_data.lstart
        if url_data.lend then url = url .. "-" .. url_data.lend end
    end
    return url
end

--- Constructs a bitbucket style url
--
-- @param url_data table containing
-- {
--  host = "<hostname>", -- e.g. bitbucket.com
--  repo = "<repo-path>", -- e.g. ruifm/gitlinker.nvim
--  rev = "revision-sha", -- the commit revision sha
--  file = "<filepath>", the file path
--  lstart = <number>/nil, the line starting range
--  lend = <number>/nil, the line ending range
-- }
--
-- @returns The url string
function M.get_bitbucket_type_url(url_data)
    local url = "https://" .. url_data.host .. "/" .. url_data.repo .. "/src/" ..
                    url_data.rev .. "/" .. url_data.file
    if url_data.lstart then
        url = url .. "#lines-" .. url_data.lstart
        if url_data.lend then url = url .. ":" .. url_data.lend end
    end
    return url
end

--- Constructs a gogs style url
--
-- @param url_data table containing
-- {
--  host = "<hostname>", -- e.g. gogs.com
--  repo = "<repo-path>", -- e.g. ruifm/gitlinker.nvim
--  rev = "revision-sha", -- the commit revision sha
--  file = "<filepath>", the file path
--  lstart = <number>/nil, the line starting range
--  lend = <number>/nil, the line ending range
-- }
--
-- @returns The url string
function M.get_gogs_type_url(url_data)
    local url = "https://" .. url_data.host .. "/" .. url_data.repo .. "/src/" ..
                    url_data.rev .. "/" .. url_data.file
    if url_data.lstart then
        url = url .. "#L" .. url_data.lstart
        if url_data.lend then url = url .. "-L" .. url_data.lend end
    end
    return url
end

--- Constructs a cgit style url
--
-- @param url_data table containing
-- {
--  host = "<hostname>", -- e.g. git.kernel.org
--  repo = "<repo-path>", -- e.g. ruifm/gitlinker.nvim
--  rev = "revision-sha", -- the commit revision sha
--  file = "<filepath>", the file path
--  lstart = <number>/nil, the line starting range
--  lend = <number>/nil, the line ending range
-- }
--
-- @returns The url string
function M.get_cgit_type_url(url_data)
    local repo = ""
    if url_data.repo then repo = url_data.repo .. ".git/" end
    local url = "https://" .. url_data.host .. "/cgit/" .. repo .. "tree/" ..
                    url_data.file .. "?id=" .. url_data.rev
    if url_data.lstart then url = url .. "#n" .. url_data.lstart end
    return url
end

--- Constructs a sourcehut style url
--
-- @param url_data table containing
-- {
--  host = "<hostname>", -- e.g. git.sr.ht
--  repo = "<repo-path>", -- e.g. ruifm/gitlinker.nvim
--  rev = "revision-sha", -- the commit revision sha
--  file = "<filepath>", the file path
--  lstart = <number>/nil, the line starting range
--  lend = <number>/nil, the line ending range
-- }
--
-- @returns The url string
function M.get_srht_type_url(url_data)
    local url = "https://" .. url_data.host .. "/" .. url_data.repo .. "/tree/" ..
                    url_data.rev .. "/item/" .. url_data.file
    if url_data.lstart then
        url = url .. "#L" .. url_data.lstart
        if url_data.lend then url = url .. "-" .. url_data.lend end
    end
    return url
end

--- Constructs a launchpad style url
--
-- @param url_data table containing
-- {
--  host = "<hostname>", -- e.g. launchpad.net
--  repo = "<repo-path>", -- e.g. ruifm/gitlinker.nvim
--  rev = "revision-sha", -- the commit revision sha
--  file = "<filepath>", the file path
--  lstart = <number>/nil, the line starting range
--  lend = <number>/nil, the line ending range
-- }
--
-- @returns The url string
function M.get_launchpad_type_url(url_data)
    local url = "https://" .. url_data.host .. "/" .. url_data.repo .. "/tree/" ..
                    url_data.file .. "?id=" .. url_data.rev
    if url_data.lstart then url = url .. "#n" .. url_data.lstart end
    return url
end

--- Constructs a repo.or.cz style url
--
-- @param url_data table containing
-- {
--  host = "<hostname>", -- e.g. repo.or.cz
--  repo = "<repo-path>", -- e.g. ruifm/gitlinker.nvim
--  rev = "revision-sha", -- the commit revision sha
--  file = "<filepath>", the file path
--  lstart = <number>/nil, the line starting range
--  lend = <number>/nil, the line ending range
-- }
--
-- @returns The url string
function M.get_repoorcz_type_url(url_data)
    local url = "https://" .. url_data.host .. "/" .. url_data.repo .. "/blob/" ..
                    url_data.rev .. ":/" .. url_data.file
    if url_data.lstart then url = url .. "#l" .. url_data.lstart end
    return url
end

--- Gets a matching callback for a given host
--
-- @param target_host the host to get the matching callback from
--
-- @returns the host's callback
function M.get_matching_callback(target_host)
    local matching_callback
    for host, callback in pairs(M.callbacks) do
        if host:match(target_host) then
            matching_callback = callback
            break
        end
    end
    if not matching_callback then
        error("No host callback defined for host '%s'", target_host)
    end
    return matching_callback
end

M.callbacks = {
        ["github.com"] = M.get_github_type_url,
        ["gitlab.com"] = M.get_gitlab_type_url,
        ["try.gitea.io"] = M.get_gitea_type_url,
        ["codeberg.org"] = M.get_gitea_type_url,
        ["bitbucket.org"] = M.get_bitbucket_type_url,
        ["try.gogs.io"] = M.get_gogs_type_url,
        ["git.sr.ht"] = M.get_srht_type_url,
        ["git.launchpad.net"] = M.get_launchpad_type_url,
        ["repo.or.cz"] = M.get_repoorcz_type_url,
        ["git.kernel.org"] = M.get_cgit_type_url,
        ["git.savannah.gnu.org"] = M.get_cgit_type_url
}

return M
