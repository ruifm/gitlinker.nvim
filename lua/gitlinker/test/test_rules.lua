local map_remote_to_host = require("gitlinker").map_remote_to_host

-- Run unit tests in nvim: `lua require('gitlinker.test.test_rules')`

-- test data:
--  input data: `git remote get-url origin/upstream/etc`
--  expected output data: git link url
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
}

for i, case in ipairs(test_cases) do
  local actual = map_remote_to_host(case[1])
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
