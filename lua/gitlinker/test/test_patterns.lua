-- Run unit tests in bash: `lua test_patterns.lua`

local a = "git@github.com:linrongbin16/gitlinker.nvim.git"
local pata = "^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"
local repa = "https://github.%1/%2/%3/blob/"
assert(a:gsub(pata, repa))

local b = "git@gitlab.com:linrongbin16/gitlinker.nvim.git"
local patb = "^git@gitlab%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"
local repb = "https://gitlab.%1/%2/%3/blob/"
assert(b:gsub(patb, repb))

print("all test patterns succeeded!")
