local M = {}

local os, open_cmd = jit.os, "xdg-open"
if os == "Darwin" then
  open_cmd = "open"
elseif os == "Windows" then
  open_cmd = "explorer"
end

local defaults = {
  remote = "origin", -- force the use of a specific remote
  add_current_line_on_normal_mode = true, -- if true adds the line nr in the url for normal mode
  action_callback = require("gitlinker.actions").copy_to_clipboard, -- callback for what to do with the url
  print_url = true, -- print the url after action
  open_cmd = open_cmd -- os-specific command to open url
}

local opts

function M.setup(user_opts)
  if not opts then
    opts = vim.tbl_deep_extend("force", {}, defaults)
  end
  opts = vim.tbl_deep_extend("force", opts, user_opts or {})
end

function M.get()
  if not opts then
    opts = vim.tbl_deep_extend("force", {}, defaults)
  end
  return opts
end

return M
