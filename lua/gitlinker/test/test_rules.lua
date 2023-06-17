local map = require("gitlinker").map_remote_to_host

-- Run unit tests in nvim: `lua require('gitlinker.test.test_rules')`

-- test data:
--  input data: `git remote get-url origin/upstream/etc`
--  expected output data: git link url
local test_cases = {
  {
    "git@github.com:linrongbin16/gitlinker.nvim.git",
    "https://github.com/linrongbin16/gitlinker.nvim/blob/",
  },
  {
    "git@github.com:linrongbin16/gitlinker.nvim",
    "https://github.com/linrongbin16/gitlinker.nvim/blob/",
  },
  {
    "https://github.com/ruifm/gitlinker.nvim.git",
    "https://github.com/ruifm/gitlinker.nvim/blob/",
  },
  {
    "https://github.com/ruifm/gitlinker.nvim",
    "https://github.com/ruifm/gitlinker.nvim/blob/",
  },
  {
    "git@github.enterprise.io:organization/repository.git",
    "https://github.enterprise.io/organization/repository/blob/",
  },
  {
    "git@github.enterprise.io:organization/repository",
    "https://github.enterprise.io/organization/repository/blob/",
  },
  {
    "https://github.enterprise.io/organization/repository.git",
    "https://github.enterprise.io/organization/repository/blob/",
  },
  {
    "https://github.enterprise.io/organization/repository",
    "https://github.enterprise.io/organization/repository/blob/",
  },
}

for i, case in ipairs(test_cases) do
  local actual = map(case[1])
  local expect = case[2]
  assert(
    actual == expect,
    string.format(
      "Failed test case [%d] - actual: `%s` != expect: `%s`",
      i,
      tostring(actual),
      tostring(expect)
    )
  )
end

print("all test cases succeeded!")
