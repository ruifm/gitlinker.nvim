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
    gitlinker.setup()
    local Linker = require("gitlinker.linker").Linker
    describe("[gitlinker]", function()
        it("_make_sharable_permalinks", function()
            local lk1 = Linker:make({ lstart = 10, lend = 23 }) --[[@as Linker]]
            if lk1 then
                local actual1 = gitlinker._make_sharable_permalinks(
                    "https://github.com/linrongbin16/gitlinker.nvim/blob/",
                    lk1
                )
                assert_eq(type(actual1), "string")
                assert_true(string.len(actual1) > 0)
                assert_eq(actual1:sub(#actual1 - 7), "#L10-L23")
                print(
                    string.format("make permalink1:%s\n", vim.inspect(actual1))
                )
            else
                assert_true(lk1 == nil)
            end

            local lk2 = Linker:make({ lstart = 17, lend = 17 }) --[[@as Linker]]
            if lk2 then
                local actual2 = gitlinker._make_sharable_permalinks(
                    "https://github.com/linrongbin16/gitlinker.nvim/blob/",
                    lk2
                )
                assert_eq(type(actual2), "string")
                assert_true(string.len(actual2) > 0)
                assert_eq(actual2:sub(#actual2 - 3), "#L17")
                print(
                    string.format("make permalink2:%s\n", vim.inspect(actual2))
                )
            else
                assert_true(lk2 == nil)
            end

            local lk3 = Linker:make() --[[@as Linker]]
            if lk3 then
                local actual3 = gitlinker._make_sharable_permalinks(
                    "https://github.com/linrongbin16/gitlinker.nvim/blob/",
                    lk3
                )
                print(
                    string.format("make permalink3:%s\n", vim.inspect(actual3))
                )
                assert_eq(type(actual3), "string")
                assert_true(string.len(actual3) > 0)
                assert_eq(actual3:sub(#actual3 - 2), "#L1")
            else
                assert_true(lk3 == nil)
            end
        end)
        it("_map_remote_to_host", function()
            local test_cases = {
                -- [1]
                {
                    "git@github.com:linrongbin16/gitlinker.nvim.git",
                    "https://github.com/linrongbin16/gitlinker.nvim/blob/",
                },
                -- [2]
                {
                    "git@github.com:linrongbin16/gitlinker.nvim",
                    "https://github.com/linrongbin16/gitlinker.nvim/blob/",
                },
                -- [3]
                {
                    "https://github.com/ruifm/gitlinker.nvim.git",
                    "https://github.com/ruifm/gitlinker.nvim/blob/",
                },
                -- [4]
                {
                    "https://github.com/ruifm/gitlinker.nvim",
                    "https://github.com/ruifm/gitlinker.nvim/blob/",
                },
                -- [5]
                {
                    "git@github.enterprise.io:organization/repository.git",
                    "https://github.enterprise.io/organization/repository/blob/",
                },
                -- [6]
                {
                    "git@github.enterprise.io:organization/repository",
                    "https://github.enterprise.io/organization/repository/blob/",
                },
                -- [7]
                {
                    "https://github.enterprise.io/organization/repository.git",
                    "https://github.enterprise.io/organization/repository/blob/",
                },
                -- [8]
                {
                    "https://github.enterprise.io/organization/repository",
                    "https://github.enterprise.io/organization/repository/blob/",
                },
                -- [9]
                {
                    "git@gitlab.com:linrongbin16/gitlinker.nvim.git",
                    "https://gitlab.com/linrongbin16/gitlinker.nvim/blob/",
                },
                -- [10]
                {
                    "git@gitlab.com:linrongbin16/gitlinker.nvim",
                    "https://gitlab.com/linrongbin16/gitlinker.nvim/blob/",
                },
                -- [11]
                {
                    "https://gitlab.com/ruifm/gitlinker.nvim.git",
                    "https://gitlab.com/ruifm/gitlinker.nvim/blob/",
                },
                -- [12]
                {
                    "https://gitlab.com/ruifm/gitlinker.nvim",
                    "https://gitlab.com/ruifm/gitlinker.nvim/blob/",
                },
                -- [13]
                {
                    "git@github.enterprise.io:organization/repository_with_single_dash1",
                    "https://github.enterprise.io/organization/repository_with_single_dash1/blob/",
                },
                -- [14]
                {
                    "https://github.enterprise.io/organization/repository____multiple___dash2.git",
                    "https://github.enterprise.io/organization/repository____multiple___dash2/blob/",
                },
            }

            for i, case in ipairs(test_cases) do
                local actual = gitlinker._map_remote_to_host(case[1])
                local expect = case[2]
                assert_eq(actual, expect)
            end
        end)
    end)
end)
