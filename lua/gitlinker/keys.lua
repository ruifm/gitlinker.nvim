local function setup(opts)
  local mapping = opts.mapping
  if mapping and string.len(mapping) > 0 then
    vim.keymap.set(
      { "n", "v" },
      mapping,
      "<cmd>lua require('gitlinker').get_buf_range_url()<cr>",
      { noremap = true, silent = true, desc = "Open git link in browser" }
    )
  end
end

local M = {
  setup = setup,
}

return M
