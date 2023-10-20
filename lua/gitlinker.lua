local git = require("gitlinker.git")
local util = require("gitlinker.util")
local logger = require("gitlinker.logger")

--- @alias Options table<any, any>
--- @type Options
local Defaults = {
    -- print permanent url in command line
    --
    --- @type boolean
    message = true,

    -- key mappings
    --
    --- @alias KeyMappingConfig {action:fun(url:string):nil,desc:string?}
    --- @type table<string, KeyMappingConfig>
    mapping = {
        ["<leader>gl"] = {
            action = require("gitlinker.actions").clipboard,
            desc = "Copy git link to clipboard",
        },
        ["<leader>gL"] = {
            action = require("gitlinker.actions").system,
            desc = "Open git link in browser",
        },
    },

    -- pattern based rules
    --- @type {[1]:table<string,string>,[2]:table<string,string>}
    pattern_rules = {
        {
            ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([_%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
            ["^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([_%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
            ["^git@gitlab%.([_%.%-%w]+):([%.%-%w]+)/([_%.%-%w]+)%.git$"] = "https://gitlab.%1/%2/%3/blob/",
            ["^https?://gitlab%.([_%.%-%w]+)/([%.%-%w]+)/([_%.%-%w]+)%.git$"] = "https://gitlab.%1/%2/%3/blob/",
        },
        {
            ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([_%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
            ["^https?://github%.([_%.%-%w]+)/([%.%-%w]+)/([_%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
            ["^git@gitlab%.([_%.%-%w]+):([%.%-%w]+)/([_%.%-%w]+)$"] = "https://gitlab.%1/%2/%3/blob/",
            ["^https?://gitlab%.([_%.%-%w]+)/([%.%-%w]+)/([_%.%-%w]+)$"] = "https://gitlab.%1/%2/%3/blob/",
        },
    },

    -- function based rules: function(remote_url) => host_url
    -- this will override the default pattern_rules.
    --
    -- here's an example:
    --
    -- ```
    -- custom_rules = function(remote_url)
    --   local rules = {
    --     {
    --       ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
    --       ["^https://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)%.git$"] = "https://github.%1/%2/%3/blob/",
    --     },
    --     -- http(s)://github.(com|*)/linrongbin16/gitlinker.nvim(.git)? -> https://github.com/linrongbin16/gitlinker.nvim(.git)?
    --     {
    --       ["^git@github%.([_%.%-%w]+):([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
    --       ["^https://github%.([_%.%-%w]+)/([%.%-%w]+)/([%.%-%w]+)$"] = "https://github.%1/%2/%3/blob/",
    --     },
    --   }
    --   for _, group in ipairs(rules) do
    --     for pattern, replace in pairs(group) do
    --       if string.match(remote_url, pattern) then
    --         local result = string.gsub(remote_url, pattern, replace)
    --         return result
    --       end
    --     end
    --   end
    --   return nil
    -- end,
    -- ```
    --
    --- @alias CustomRules fun(remote_url:string):string?
    --- @type CustomRules?
    custom_rules = nil,

    -- enable debug
    --- @type boolean
    debug = false,

    -- write logs to console(command line)
    --- @type boolean
    console_log = true,

    -- write logs to file
    --- @type boolean
    file_log = false,
}

--- @type Options
local Configs = {}

--- @param option Options?
local function setup(option)
    Configs = vim.tbl_deep_extend("force", Defaults, option or {})

    -- logger
    logger.setup({
        level = Configs.debug and "DEBUG" or "INFO",
        console_log = Configs.console_log,
        file_log = Configs.file_log,
    })

    local key_mappings = nil
    if type(option) == "table" and option["mapping"] ~= nil then
        if type(option["mapping"]) == "table" then
            key_mappings = option["mapping"]
        end
    else
        key_mappings = Defaults.mapping
    end

    -- key mapping
    if type(key_mappings) == "table" then
        for k, v in pairs(key_mappings) do
            local opt = {
                noremap = true,
                silent = true,
            }
            if v.desc then
                opt.desc = v.desc
            end
            vim.keymap.set({ "n", "v" }, k, function()
                require("gitlinker").link({ action = v.action })
            end, opt)
        end
    end

    -- logger.debug("|setup| Configs:%s", vim.inspect(Configs))
end

--- @class Linker
--- @field remote_url string
--- @field rev string
--- @field file string
--- @field lstart integer
--- @field lend integer
--- @field file_changed boolean
local Linker = {}

--- @param remote_url string
--- @param rev string
--- @param file string
--- @param lstart integer
--- @param lend integer
--- @param file_changed boolean
--- @return Linker
local function new_linker(remote_url, rev, file, lstart, lend, file_changed)
    local linker = vim.tbl_extend("force", vim.deepcopy(Linker), {
        remote_url = remote_url,
        rev = rev,
        file = file,
        lstart = lstart,
        lend = lend,
        file_changed = file_changed,
    })
    return linker
end

--- @return Linker?
local function make_link_data(range)
    local root = git.get_root()
    if not root then
        return nil
    end

    --- @type string|nil
    local remote = git.get_branch_remote()
    if not remote then
        return nil
    end
    logger.debug("|make_link_data| remote:%s", vim.inspect(remote))

    local remote_url_result = git.get_remote_url(remote)
    if not remote_url_result then
        return nil
    end
    logger.debug(
        "|make_link_data| remote_url_result:%s",
        vim.inspect(remote_url_result)
    )

    --- @type string|nil
    local rev = git.get_closest_remote_compatible_rev(remote)
    if not rev then
        return nil
    end
    logger.debug("|make_link_data| rev:%s", vim.inspect(rev))

    local buf_path_on_root = util.path_relative(root) --[[@as string]]
    logger.debug(
        "|make_link_data| root:%s, buf_path_on_root:%s",
        vim.inspect(root),
        vim.inspect(buf_path_on_root)
    )

    local file_in_rev_result = git.is_file_in_rev(buf_path_on_root, rev)
    if not file_in_rev_result then
        return nil
    end
    logger.debug(
        "|make_link_data| file_in_rev_result:%s",
        vim.inspect(file_in_rev_result)
    )

    local buf_path_on_cwd = util.path_relative() --[[@as string]]
    logger.debug(
        "|make_link_data| buf_path_on_cwd:%s",
        vim.inspect(buf_path_on_cwd)
    )

    if range == nil or range["lstart"] == nil or range["lend"] == nil then
        range = util.line_range()
        logger.debug("[make_link_data] range:%s", vim.inspect(range))
    end

    return new_linker(
        remote_url_result,
        rev,
        buf_path_on_root,
        range.lstart,
        range.lend,
        git.has_file_changed(buf_path_on_cwd, rev)
    )
end

--- @package
--- @param remote_url string
--- @return string?
local function _map_remote_to_host(remote_url)
    local custom_rules = Configs.custom_rules
    if type(custom_rules) == "function" then
        return custom_rules(remote_url)
    end

    local pattern_rules = Configs.pattern_rules
    for i, group in ipairs(pattern_rules) do
        for pattern, replace in pairs(group) do
            -- logger.debug(
            --   "[map_remote_to_host] map group[%d], pattern:'%s', replace:'%s'",
            --   i,
            --   pattern,
            --   replace
            -- )
            if string.match(remote_url, pattern) then
                local host_url = string.gsub(remote_url, pattern, replace)
                -- logger.debug(
                --   "[map_remote_to_host] map group[%d] matched, pattern:'%s', replace:'%s', remote_url:'%s' => host_url:'%s'",
                --   i,
                --   pattern,
                --   replace,
                --   remote_url,
                --   host_url
                -- )
                return host_url
            end
        end
    end

    return nil
end

--- @param host_url string
--- @param linker Linker
--- @return string
local function make_sharable_permalinks(host_url, linker)
    local url = host_url .. linker.rev .. "/" .. linker.file
    if not linker.lstart then
        return url
    end
    url = url .. "#L" .. linker.lstart
    if linker.lend and linker.lend ~= linker.lstart then
        url = url .. "-L" .. linker.lend
    end
    return url
end

--- @param opts Options
--- @return string?
local function link(opts)
    opts = vim.tbl_deep_extend("force", Configs, opts or {})
    logger.debug("[link] merged opts: %s", vim.inspect(opts))

    local range = nil
    if opts["lstart"] ~= nil and opts["lend"] ~= nil then
        range = { lstart = opts["lstart"], lend = opts["lend"] }
    end
    local linker = make_link_data(range)
    if not linker then
        return nil
    end

    local host_url = _map_remote_to_host(linker.remote_url)

    if type(host_url) ~= "string" or string.len(host_url) <= 0 then
        logger.err(
            "Error! Cannot generate git link from remote url:%s",
            linker.remote_url
        )
        return nil
    end

    local url = make_sharable_permalinks(host_url, linker)

    if opts.action then
        opts.action(url)
    end
    if opts.message then
        local msg = linker.file_changed
                and string.format(
                    "%s (lines can be wrong due to file change)",
                    url
                )
            or url
        logger.info(msg)
    end

    return url
end

local M = {
    setup = setup,
    link = link,
    _map_remote_to_host = _map_remote_to_host,
}

return M
