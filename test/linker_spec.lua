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
  describe("[_parse_remote_url]", function()
    it("parse git", function()
      local parsed = linker._parse_remote_url(
        "git@github.com:linrongbin16/gitlinker.nvim.git"
      )
      assert_eq(type(parsed), "table")
      assert_eq(parsed.protocol, "git")
      assert_eq(parsed.host, "github.com")
      assert_eq(parsed.user, "linrongbin16")
      assert_eq(parsed.repo, "gitlinker.nvim.git")
    end)
    it("parse http", function()
      local parsed = linker._parse_remote_url(
        "http://github.com/linrongbin16/gitlinker.nvim.git"
      )
      assert_eq(type(parsed), "table")
      assert_eq(parsed.protocol, "http")
      assert_eq(parsed.host, "github.com")
      assert_eq(parsed.user, "linrongbin16")
      assert_eq(parsed.repo, "gitlinker.nvim.git")
    end)
    it("parse https", function()
      local parsed = linker._parse_remote_url(
        "https://github.com/linrongbin16/gitlinker.nvim.git"
      )
      assert_eq(type(parsed), "table")
      assert_eq(parsed.protocol, "https")
      assert_eq(parsed.host, "github.com")
      assert_eq(parsed.user, "linrongbin16")
      assert_eq(parsed.repo, "gitlinker.nvim.git")
    end)
  end)
  describe("[make_linker]", function()
    it("make", function()
      local lk = linker.make_linker() --[[@as gitlinker.Linker]]
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
      local lk = linker.make_linker({ lstart = 10, lend = 20 }) --[[@as gitlinker.Linker]]
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
