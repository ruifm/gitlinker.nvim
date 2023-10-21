local cwd = vim.fn.getcwd()

describe("path", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
        vim.opt.swapfile = false
    end)

    local logger = require("gitlinker.logger")
    logger.setup()
    local path = require("gitlinker.path")
    describe("[normalize]", function()
        it("normalize", function()
            local lines = {
                "~/github/linrongbin16/gitlinker.nvim/README.md",
                "~/github/linrongbin16/gitlinker.nvim/lua/gitlinker.lua",
            }
            for i, line in ipairs(lines) do
                local actual = path.normalize(line)
                local expect = vim.fn.expand(line)
                print(
                    string.format(
                        "path normalize[%d]:%s == %s\n",
                        i,
                        actual,
                        expect
                    )
                )
                assert_eq(actual, expect)
            end
        end)
        it("relative", function()
            local lines = {
                "README.md",
                "lua/gitlinker.lua",
                "lua/gitlinker/path.lua",
            }
            for i, line in ipairs(lines) do
                vim.cmd(string.format([[ edit %s ]], line))
                local actual = path.buffer_relpath()
                print(string.format("path relative:%s\n", actual))
                assert_eq(actual, line)
            end
        end)
    end)
end)
