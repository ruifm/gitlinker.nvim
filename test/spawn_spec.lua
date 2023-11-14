local cwd = vim.fn.getcwd()

describe("spawn", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local spawn = require("gitlinker.spawn")

  describe("[string_find]", function()
    it("found", function()
      assert_eq(spawn.string_find("abcdefg", "a"), 1)
      assert_eq(spawn.string_find("abcdefg", "a", 1), 1)
      assert_eq(spawn.string_find("abcdefg", "g"), 7)
      assert_eq(spawn.string_find("abcdefg", "g", 1), 7)
      assert_eq(spawn.string_find("abcdefg", "g", 7), 7)
      assert_eq(spawn.string_find("fzfx -- -w -g *.lua", "--"), 6)
      assert_eq(spawn.string_find("fzfx -- -w -g *.lua", "--", 1), 6)
      assert_eq(spawn.string_find("fzfx -- -w -g *.lua", "--", 2), 6)
      assert_eq(spawn.string_find("fzfx -- -w -g *.lua", "--", 3), 6)
      assert_eq(spawn.string_find("fzfx -- -w -g *.lua", "--", 6), 6)
      assert_eq(spawn.string_find("fzfx -w -- -g *.lua", "--"), 9)
      assert_eq(spawn.string_find("fzfx -w -- -g *.lua", "--", 1), 9)
      assert_eq(spawn.string_find("fzfx -w -- -g *.lua", "--", 2), 9)
      assert_eq(spawn.string_find("fzfx -w ---g *.lua", "--", 8), 9)
      assert_eq(spawn.string_find("fzfx -w ---g *.lua", "--", 9), 9)
    end)
    it("not found", function()
      assert_eq(spawn.string_find("abcdefg", "a", 2), nil)
      assert_eq(spawn.string_find("abcdefg", "a", 7), nil)
      assert_eq(spawn.string_find("abcdefg", "g", 8), nil)
      assert_eq(spawn.string_find("abcdefg", "g", 9), nil)
      assert_eq(spawn.string_find("fzfx -- -w -g *.lua", "--", 7), nil)
      assert_eq(spawn.string_find("fzfx -- -w -g *.lua", "--", 8), nil)
      assert_eq(spawn.string_find("fzfx -w -- -g *.lua", "--", 10), nil)
      assert_eq(spawn.string_find("fzfx -w -- -g *.lua", "--", 11), nil)
      assert_eq(spawn.string_find("fzfx -w ---g *.lua", "--", 11), nil)
      assert_eq(spawn.string_find("fzfx -w ---g *.lua", "--", 12), nil)
      assert_eq(spawn.string_find("", "--"), nil)
      assert_eq(spawn.string_find("", "--", 1), nil)
      assert_eq(spawn.string_find("-", "--"), nil)
      assert_eq(spawn.string_find("--", "---", 1), nil)
    end)
  end)
  describe("[Spawn]", function()
    it("open", function()
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = function() end }
      ) --[[@as Spawn]]
      assert_eq(type(sp), "table")
      assert_eq(type(sp.cmds), "table")
      assert_eq(#sp.cmds, 2)
      assert_eq(sp.cmds[1], "cat")
      assert_eq(sp.cmds[2], "README.md")
      assert_eq(type(sp.out_pipe), "userdata")
      assert_eq(type(sp.err_pipe), "userdata")
    end)
    it("consume line", function()
      local content = spawn.readfile("README.md") --[[@as string]]
      local lines = spawn.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        print(string.format("actual:[%d]%s\n", i, line))
        print(string.format("expect:[%d]%s\n", i, lines[i]))
        assert_eq(type(line), "string")
        assert_eq(line, lines[i])
        i = i + 1
      end
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line }
      ) --[[@as Spawn]]
      local pos = sp:_consume_line(content, process_line)
      if pos <= #content then
        local line = content:sub(pos, #content)
        process_line(line)
      end
    end)
    it("stdout on newline", function()
      local content = spawn.readfile("README.md") --[[@as string]]
      local lines = spawn.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(line, lines[i])
        i = i + 1
      end
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line }
      ) --[[@as Spawn]]
      local content_splits =
        vim.split(content, "\n", { plain = true, trimempty = false })
      for j, splits in ipairs(content_splits) do
        sp:_on_stdout(nil, splits)
        if j < #content_splits then
          sp:_on_stdout(nil, "\n")
        end
      end
      sp:_on_stdout(nil, nil)
      assert_true(sp.out_pipe:is_closing())
    end)
    it("stdout on whitespace", function()
      local content = spawn.readfile("README.md") --[[@as string]]
      local lines = spawn.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(line, lines[i])
        i = i + 1
      end
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line }
      ) --[[@as Spawn]]
      local content_splits =
        vim.split(content, " ", { plain = true, trimempty = false })
      for j, splits in ipairs(content_splits) do
        sp:_on_stdout(nil, splits)
        if j < #content_splits then
          sp:_on_stdout(nil, " ")
        end
      end
      sp:_on_stdout(nil, nil)
      assert_true(sp.out_pipe:is_closing())
    end)
    for delimiter_i = 0, 25 do
      -- lower case: a
      local lower_char = string.char(97 + delimiter_i)
      it(string.format("stdout on %s", lower_char), function()
        local content = spawn.readfile("README.md") --[[@as string]]
        local lines = spawn.readlines("README.md") --[[@as table]]

        local i = 1
        local function process_line(line)
          -- print(string.format("[%d]%s\n", i, line))
          assert_eq(type(line), "string")
          assert_eq(line, lines[i])
          i = i + 1
        end
        local sp = spawn.Spawn:make(
          { "cat", "README.md" },
          { on_stdout = process_line }
        ) --[[@as Spawn]]
        local content_splits =
          vim.split(content, lower_char, { plain = true, trimempty = false })
        for j, splits in ipairs(content_splits) do
          sp:_on_stdout(nil, splits)
          if j < #content_splits then
            sp:_on_stdout(nil, lower_char)
          end
        end
        sp:_on_stdout(nil, nil)
        assert_true(sp.out_pipe:is_closing())
      end)
      -- upper case: A
      local upper_char = string.char(65 + delimiter_i)
      it(string.format("stdout on %s", upper_char), function()
        local content = spawn.readfile("README.md") --[[@as string]]
        local lines = spawn.readlines("README.md") --[[@as table]]

        local i = 1
        local function process_line(line)
          -- print(string.format("[%d]%s\n", i, line))
          assert_eq(type(line), "string")
          assert_eq(line, lines[i])
          i = i + 1
        end
        local sp = spawn.Spawn:make(
          { "cat", "README.md" },
          { on_stdout = process_line }
        ) --[[@as Spawn]]
        local content_splits =
          vim.split(content, upper_char, { plain = true, trimempty = false })
        for j, splits in ipairs(content_splits) do
          sp:_on_stdout(nil, splits)
          if j < #content_splits then
            sp:_on_stdout(nil, upper_char)
          end
        end
        sp:_on_stdout(nil, nil)
        assert_true(sp.out_pipe:is_closing())
      end)
    end
    it("stderr", function()
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = function() end }
      ) --[[@as Spawn]]
      sp:_on_stderr(nil, nil)
      assert_true(sp.err_pipe:is_closing())
    end)
    it("iterate on README.md", function()
      local lines = spawn.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(lines[i], line)
        i = i + 1
      end

      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line }
      ) --[[@as Spawn]]
      sp:run()
    end)
    it("iterate on lua/gitlinker.lua", function()
      local lines = spawn.readlines("lua/gitlinker.lua") --[[@as table]]

      local i = 1
      local function process_line(line)
        print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(lines[i], line)
        i = i + 1
      end

      local sp = spawn.Spawn:make(
        { "cat", "lua/gitlinker.lua" },
        { on_stdout = process_line }
      ) --[[@as Spawn]]
      sp:run()
    end)
    it("close handle", function()
      local sp = spawn.Spawn:make(
        { "cat", "lua/gitlinker.lua" },
        { on_stdout = function() end }
      ) --[[@as Spawn]]
      sp:run()
      assert_true(sp.process_handle ~= nil)
      sp:_close_handle(sp.process_handle)
      assert_true(sp.process_handle:is_closing())
    end)
  end)
end)
