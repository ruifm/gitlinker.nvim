local M = {}

local api = vim.api

local function set_keymap(mode, keys)
  local mapping_opts = {noremap = true, silent = true}
  api.nvim_set_keymap(mode, keys,
                      ":lua require'gitlinker'.get_buf_range_url('" .. mode ..
                        "')<cr>", mapping_opts)
end

function M.set(mappings)
  if not mappings then return end
  set_keymap("n", mappings)
  set_keymap("v", mappings)
end

return M
