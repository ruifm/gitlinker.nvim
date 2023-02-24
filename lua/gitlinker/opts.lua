local DEFAULTS = {
  -- open_in_browser/copy_to_clipboard
  action = require("gitlinker.actions").open_in_browser,
  -- print message(git host url) in command line
  message = true,
  -- key mapping
  mapping = "<leader>gl",
  -- regex pattern based rules
  pattern_rules = {
    -- git@github.(com|*):linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
    {
      ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
      ["^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
    },
    -- http(s)://github.(com|*)/linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
    {
      ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
      ["^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
    },
  },
  -- function based rules: function(remote_url) -> host_url
  -- @param remote_url    A string value for git remote url.
  -- @return              A string value for git host url.
  custom_rules = nil,
  -- here's an example of custom_rules:
  --
  -- custom_rules = function(remote_url)
  --   local rules = {
  --     {
  --       ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
  --       ["^https://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
  --     },
  --     -- http(s)://github.(com|*)/linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
  --     {
  --       ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
  --       ["^https://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
  --     },
  --   }
  --   for _, group in ipairs(rules) do
  --     for pattern, replace in pairs(group) do
  --       if string.match(remote_url, pattern) then
  --         local result = string.gsub(remote_url, pattern, replace)
  --         return result
  --       end
  --     end
  --   end
  --   return nil
  -- end,

  -- enable debug
  debug = false,
  -- write logs to console(command line)
  console_log = true,
  -- write logs to file
  file_log = false,
  -- file name to write logs, working with `file_log=true`
  file_log_name = "gitlinker.log",
}

local action = nil
local message = nil
local mapping = nil
local pattern_rules = nil
local custom_rules = nil
local debug = nil
local console_log = nil
local file_log = nil
local file_log_name = nil

local function setup(user_opts)
  action = (user_opts and user_opts.action) and user_opts.action
      or DEFAULTS.action
  message = (user_opts and user_opts.message) and user_opts.message
      or DEFAULTS.message
  mapping = (user_opts and user_opts.mapping) and user_opts.mapping
      or DEFAULTS.mapping
  pattern_rules = (user_opts and user_opts.pattern_rules)
      and user_opts.pattern_rules
      or DEFAULTS.pattern_rules
  custom_rules = (user_opts and user_opts.custom_rules)
      and user_opts.custom_rules
      or DEFAULTS.custom_rules
  debug = (user_opts and user_opts.debug) and user_opts.debug or DEFAULTS.debug
  console_log = (user_opts and user_opts.console_log) and user_opts.console_log
      or DEFAULTS.console_log
  file_log = (user_opts and user_opts.file_log) and user_opts.file_log
      or DEFAULTS.file_log
  file_log_name = (user_opts and user_opts.file_log_name)
      and user_opts.file_log_name
      or DEFAULTS.file_log_name
end

local M = {
  setup = setup,
  action = action,
  message = message,
  mapping = mapping,
  pattern_rules = pattern_rules,
  custom_rules = custom_rules,
  debug = debug,
  console_log = console_log,
  file_log = file_log,
  file_log_name = file_log_name,
}

return M
