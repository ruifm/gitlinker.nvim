local M = {}

local hosts = require("gitlinker.hosts")

local defaults = {
  action_callback = require("gitlinker.actions").open_in_browser, -- callback for what to do with the url
  print_url = true, -- print the url after action
  mappings = "<leader>gl", -- key mappings
  callbacks = {
    ["github.com"] = hosts.get_github_type_url,
    ["gitlab.com"] = hosts.get_gitlab_type_url,
    ["bitbucket.org"] = hosts.get_bitbucket_type_url,
  },
  -- use regex to match remote url and generate git link url
  pattern_rules = {
    -- git@github.(com|*):linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
    ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
    -- http(s)://github.(com|*)/linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
    ["^https://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
  },
  -- use custom rules to generate git link url
  -- custom_rules = function(remote_url)
  --   local pattern_rules = {
  --     -- git@github.(com|*):linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
  --     ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
  --     -- http(s)://github.(com|*)/linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
  --     ["^https://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
  --   }
  --   for pattern, replace in pairs(pattern_rules) do
  --     if string.match(remote_url, pattern) then
  --       local result = string.gsub(remote_url, pattern, replace)
  --       return result
  --     end
  --   end
  --   print("result: nil")
  --   return nil
  -- end,
  custom_rules = nil,
  debug = false,
  console_log = true,
  file_log = false,
  file_log_name = "gitlinker.log",
}

local opts

function M.setup(user_opts)
  opts = vim.tbl_deep_extend("force", defaults, user_opts or {})
end

function M.get()
  return opts
end

return M
