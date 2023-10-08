local cwd = vim.fn.getcwd()

describe("lua_pattern", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    describe("[lua_pattern]", function()
        it("test patterns", function()
            local a = "git@github.com:linrongbin16/gitlinker.nvim.git"
            local pata =
                "^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"
            local repa = "https://github.%1/%2/%3/blob/"
            assert_true(a:gsub(pata, repa) ~= nil)

            local b = "git@gitlab.com:linrongbin16/gitlinker.nvim.git"
            local patb =
                "^git@gitlab%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"
            local repb = "https://gitlab.%1/%2/%3/blob/"
            assert_true(b:gsub(patb, repb) ~= nil)
        end)
    end)
end)
