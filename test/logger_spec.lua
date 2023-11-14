local cwd = vim.fn.getcwd()

describe("logger", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local logger = require("gitlinker.logger")
  logger.setup({
    level = "DEBUG",
    console_log = true,
    file_log = true,
  })
  describe("[logger]", function()
    it("debug", function()
      logger.debug("debug without parameters")
      logger.debug("debug with 1 parameters: %s", "a")
      logger.debug("debug with 2 parameters: %s, %d", "a", 1)
      logger.debug("debug with 3 parameters: %s, %d, %f", "a", 1, 3.12)
      assert_true(true)
    end)
    it("info", function()
      logger.info("info without parameters")
      logger.info("info with 1 parameters: %s", "a")
      logger.info("info with 2 parameters: %s, %d", "a", 1)
      logger.info("info with 3 parameters: %s, %d, %f", "a", 1, 3.12)
      assert_true(true)
    end)
    it("warn", function()
      logger.warn("warn without parameters")
      logger.warn("warn with 1 parameters: %s", "a")
      logger.warn("warn with 2 parameters: %s, %d", "a", 1)
      logger.warn("warn with 3 parameters: %s, %d, %f", "a", 1, 3.12)
      assert_true(true)
    end)
    it("err", function()
      logger.err("err without parameters")
      logger.err("err with 1 parameters: %s", "a")
      logger.err("err with 2 parameters: %s, %d", "a", 1)
      logger.err("err with 3 parameters: %s, %d, %f", "a", 1, 3.12)
      assert_true(true)
    end)
    it("throw", function()
      local ok, errmsg = pcall(logger.throw, "throw without parameters")
      assert_true(not ok)
      assert_eq(type(errmsg), "string")
      assert_true(string.len(errmsg) > 0)
    end)
    it("ensure", function()
      local ok1, err1 =
        pcall(logger.ensure, true, "ensure true without parameters")
      assert_true(ok1)
      local ok2, err2 =
        pcall(logger.ensure, false, "ensure false without parameters")
      assert_true(not ok2)
      assert_eq(type(err2), "string")
      assert_true(string.len(err2) > 0)
    end)
  end)
end)
