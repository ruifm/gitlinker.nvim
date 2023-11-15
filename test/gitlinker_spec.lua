local cwd = vim.fn.getcwd()

describe("gitlinker", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    local logger = require("gitlinker.logger")
    logger.setup()
    vim.cmd([[ edit lua/gitlinker.lua ]])
  end)

  local gitlinker = require("gitlinker")
  local utils = require("gitlinker.utils")
  describe("[link]", function()
    it("link", function()
      gitlinker.setup()
      local actual = gitlinker.link({
        action = require("gitlinker.actions").clipboard,
        router = require("gitlinker.routers").blob,
      })
      print(string.format("link:%s\n", vim.inspect(actual)))
      if actual then
        assert_eq(type(actual), "string")
        assert_true(
          utils.string_startswith(
            actual,
            "https://github.com/linrongbin16/gitlinker.nvim/blob"
          )
        )
      end
    end)
  end)
end)
