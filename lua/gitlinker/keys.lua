local function setup(mapping)
  if mapping and #mapping > 0 then
    for k, v in pairs(mapping) do
      local opt = {
        noremap = true,
        silent = true,
      }
      if v.desc then
        opt.desc = v.desc
      end
      vim.keymap.set({ "n", "v" }, k, function()
        require("gitlinker").link({ action = v.action })
      end, opt)
    end
  end
end

local M = {
  setup = setup,
}

return M
