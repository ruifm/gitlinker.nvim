local cwd = vim.fn.getcwd()

describe("git", function()
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

  local logger = require("gitlinker.logger")
  logger.setup({
    level = "DEBUG",
    console_log = true,
    file_log = true,
  })
  local git = require("gitlinker.git")
  local path = require("gitlinker.path")
  describe("[git]", function()
    it("_get_remote", function()
      local r = git._get_remote()
      print(string.format("_get_remote:%s\n", vim.inspect(r)))
      assert_eq(type(r), "table")
    end)
    it("get_remote_url", function()
      local remote = git.get_branch_remote()
      print(string.format("get_branch_remote:%s\n", vim.inspect(remote)))
      if remote then
        assert_eq(type(remote), "string")
        assert_true(string.len(remote) > 0)
        local r = git.get_remote_url(remote)
        print(string.format("get_remote_url:%s\n", vim.inspect(r)))
        assert_eq(type(r), "string")
        assert_true(string.len(r) > 0)
      else
        assert_true(remote == nil)
      end
    end)
    it("_get_rev(@{u})", function()
      local rev = git._get_rev("@{u}")
      if rev then
        print(string.format("_get_rev:%s\n", vim.inspect(rev)))
        assert_eq(type(rev), "string")
        assert_true(string.len(rev) > 0)
      else
        assert_true(rev == nil)
      end
    end)
    it("_get_rev_name(@{u})", function()
      local rev = git._get_rev_name("@{u}")
      if rev then
        print(string.format("_get_rev_name:%s\n", vim.inspect(rev)))
        assert_eq(type(rev), "string")
        assert_true(string.len(rev) > 0)
      else
        assert_true(rev == nil)
      end
    end)
    it("is_file_in_rev", function()
      local remote = git.get_branch_remote()
      if not remote then
        assert_true(remote == nil)
        return
      end
      assert_eq(type(remote), "string")
      assert_true(string.len(remote) > 0)
      local remote_url = git.get_remote_url(remote)
      if not remote_url then
        assert_true(remote_url == nil)
        return
      end
      assert_eq(type(remote_url), "string")
      assert_true(string.len(remote_url) > 0)

      local rev = git.get_closest_remote_compatible_rev(remote) --[[@as string]]
      if not rev then
        assert_true(rev == nil)
        return
      end
      assert_eq(type(rev), "string")
      assert_true(string.len(rev) > 0)

      local bufpath = path.buffer_relpath() --[[@as string]]
      if not bufpath then
        assert_true(bufpath == nil)
        return
      end
      local actual = git.is_file_in_rev(bufpath, rev)
      if actual ~= nil then
        print(string.format("is_file_in_rev:%s\n", vim.inspect(actual)))
      else
        assert_true(actual == nil)
      end
    end)
    it("resolve_host", function()
      local actual = git.resolve_host("github.com")
      assert_eq(actual, "github.com")
    end)
  end)
end)
