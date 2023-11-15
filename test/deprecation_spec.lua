local cwd = vim.fn.getcwd()

describe("deprecation", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local deprecation = require("gitlinker.deprecation")
  describe("[notify]", function()
    it("notify", function()
      deprecation.notify("deprecate")
      deprecation.notify("deprecate %s", "asdf")
      deprecation.notify("deprecate %s %d", "asdf", 1)
    end)
  end)
end)
