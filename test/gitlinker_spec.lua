local cwd = vim.fn.getcwd()

describe("gitlinker", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local gitlinker = require("gitlinker")
    gitlinker.setup()
    describe("[gitlinker]", function()
        it("map_remote_to_host", function()
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
