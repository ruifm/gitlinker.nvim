local cwd = vim.fn.getcwd()

describe("linker", function()
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

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"
  local linker = require("gitlinker.linker")
  describe("[Linker]", function()
    it("make", function()
      local lk = linker.Linker:make() --[[@as Linker]]
      print(string.format("linker:%s", vim.inspect(lk)))
      if github_actions then
        assert_true(type(lk) == "table" or lk == nil)
      else
        assert_eq(type(lk), "table")
        assert_eq(lk.file, "lua/gitlinker.lua")
        assert_eq(lk.lstart, 1)
        assert_eq(lk.lend, 1)
        assert_eq(type(lk.rev), "string")
        assert_true(string.len(lk.rev) > 0)
        assert_eq(type(lk.remote_url), "string")
        assert_eq(
          lk.remote_url,
          "https://github.com/linrongbin16/gitlinker.nvim.git"
        )
      end
    end)
    it("make with range", function()
      local lk = linker.Linker:make({ lstart = 10, lend = 20 }) --[[@as Linker]]
      print(string.format("linker:%s", vim.inspect(lk)))
      if github_actions then
        assert_true(type(lk) == "table" or lk == nil)
      else
        assert_eq(type(lk), "table")
        assert_eq(lk.file, "lua/gitlinker.lua")
        assert_eq(lk.lstart, 10)
        assert_eq(lk.lend, 20)
        assert_eq(type(lk.rev), "string")
        assert_true(string.len(lk.rev) > 0)
        assert_eq(type(lk.remote_url), "string")
        assert_eq(
          lk.remote_url,
          "https://github.com/linrongbin16/gitlinker.nvim.git"
        )
      end
    end)
  end)
end)
