local function setup(mapping)
  if mapping and string.len(mapping) > 0 then
    vim.keymap.set(
      { "n", "v" },
      mapping,
      "<cmd>lua require('gitlinker').link()<cr>",
      { noremap = true, silent = true, desc = "Open git link in browser" }
    )
  end
end

local M = {
  setup = setup,
}

return M
