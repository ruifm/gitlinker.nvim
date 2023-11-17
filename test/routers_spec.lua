local cwd = vim.fn.getcwd()

describe("routers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
  end)

  local utils = require("gitlinker.utils")
  local linker = require("gitlinker.linker")
  local routers = require("gitlinker.routers")
  require("gitlinker").setup({
    debug = true,
    file_log = true,
  })
  describe("[browse]", function()
    it("bitbucket without line numbers", function()
      local actual = routers.bitbucket_browse({
        remote_url = "git@bitbucket.org:linrongbin16/gitlinker.nvim.git",
        protocol = "git@",
        host = "bitbucket.org",
        user = "linrongbin16",
        repo = "gitlinker.nvim.git",
        rev = "399b1d05473c711fc5592a6ffc724e231c403486",
        file = "lua/gitlinker/logger.lua",
        file_changed = false,
      } --[[@as gitlinker.Linker]])
      assert_eq(
        actual,
        "https://bitbucket.org/linrongbin16/gitlinker.nvim/src/399b1d05473c711fc5592a6ffc724e231c403486/lua/gitlinker/logger.lua"
      )
    end)
    it("bitbucket with line start", function()
      local actual = routers.bitbucket_browse({
        remote_url = "git@bitbucket.org:linrongbin16/gitlinker.nvim.git",
        protocol = "git@",
        host = "bitbucket.org",
        user = "linrongbin16",
        repo = "gitlinker.nvim.git",
        rev = "399b1d05473c711fc5592a6ffc724e231c403486",
        file = "lua/gitlinker/logger.lua",
        lstart = 1,
        lend = 2,
        file_changed = false,
      }--[[@as gitlinker.Linker]])
      assert_eq(
        actual,
        "https://bitbucket.org/linrongbin16/gitlinker.nvim/src/399b1d05473c711fc5592a6ffc724e231c403486/lua/gitlinker/logger.lua#lines-1:2"
      )
    end)
  end)
  describe("[blame]", function()
    it("bitbucket without line numbers", function()
      local actual = routers.bitbucket_blame({
        remote_url = "git@github.com:linrongbin16/gitlinker.nvim.git",
        protocol = "git@",
        host = "github.com",
        user = "linrongbin16",
        repo = "gitlinker.nvim.git",
        rev = "399b1d05473c711fc5592a6ffc724e231c403486",
        file = "lua/gitlinker/logger.lua",
        file_changed = false,
      } --[[@as gitlinker.Linker]])
      assert_eq(
        actual,
        "https://github.com/linrongbin16/gitlinker.nvim/annotate/399b1d05473c711fc5592a6ffc724e231c403486/lua/gitlinker/logger.lua"
      )
    end)
    it("bitbucket with line start", function()
      local actual = routers.bitbucket_blame({
        remote_url = "git@github.com:linrongbin16/gitlinker.nvim.git",
        protocol = "git@",
        host = "github.com",
        user = "linrongbin16",
        repo = "gitlinker.nvim.git",
        rev = "399b1d05473c711fc5592a6ffc724e231c403486",
        file = "lua/gitlinker/logger.lua",
        lstart = 1,
        lend = 2,
        file_changed = false,
      }--[[@as gitlinker.Linker]])
      assert_eq(
        actual,
        "https://github.com/linrongbin16/gitlinker.nvim/annotate/399b1d05473c711fc5592a6ffc724e231c403486/lua/gitlinker/logger.lua#lines-1:2"
      )
    end)
  end)
end)
