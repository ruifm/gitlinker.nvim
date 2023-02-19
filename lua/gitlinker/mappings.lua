local M = {}

local api = vim.api

local function set_keymap(mode, keys, mapping_opts)
  mapping_opts = vim.tbl_extend(
    "force",
    { noremap = true, silent = true },
    mapping_opts or {}
  )
  api.nvim_set_keymap(
    mode,
    keys,
    "<cmd>lua require'gitlinker'.get_buf_range_url('" .. mode .. "')<cr>",
    mapping_opts
  )
end

function M.set(mappings)
  mappings = require("gitlinker.opts").get().mappings
  if mappings and string.len(mappings) > 0 then
    set_keymap("n", mappings)
    set_keymap("v", mappings, { silent = false })
  end
end

return M
