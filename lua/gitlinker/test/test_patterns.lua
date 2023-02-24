-- Run unit tests in bash: `lua test_patterns.lua`

local a = "git@github.com:linrongbin16/gitlinker.nvim.git"
local pat = "^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"
local rep = "https://github.%1/%2/%3/blob/"
assert(a:gsub(pat, rep))
