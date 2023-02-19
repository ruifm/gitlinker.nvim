local M = {}

local defaults = {
  remote = "origin", -- force the use of a specific remote
  add_current_line_on_normal_mode = true, -- if true adds the line nr in the url for normal mode
  action_callback = require("gitlinker.actions").open_in_browser, -- callback for what to do with the url
  print_url = true, -- print the url after action
  mappings = "<leader>gl", -- key mappings
  callbacks = {
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
    ["git.savannah.gnu.org"] = M.get_cgit_type_url,
  },
  debug = false,
}

local opts

function M.setup(user_opts)
  opts = vim.tbl_deep_extend("force", defaults, user_opts or {})
end

function M.get()
  return opts
end

return M
