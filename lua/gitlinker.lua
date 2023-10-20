local git = require("gitlinker.git")
local util = require("gitlinker.util")
local logger = require("gitlinker.logger")

--- @alias Configs table<any, any>
--- @type Configs
local Defaults = {
    -- print message(git host url) in command line
    --- @type boolean
    message = true,

    -- key mapping
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

    -- regex pattern based rules
    --- @type table<string, string>[]
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

--- @type Configs
local Configs = {}

--- @param option Configs?
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
    if key_mappings then
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

    logger.debug("[setup] opts: %s", vim.inspect(Configs))
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

--- @return Linker|nil
local function make_link_data(range)
    --- @type JobResult
    local root_result = git.get_root()
    if not git.result_has_out(root_result) then
        git.result_print_err(root_result, "not in a git repository")
        return nil
    end
    logger.debug(
        "|make_link_data| root_result(%s):%s",
        vim.inspect(type(root_result)),
        vim.inspect(root_result)
    )

    --- @type string|nil
    local remote = git.get_branch_remote()
    if not remote then
        return nil
    end
    logger.debug(
        "|make_link_data| remote(%s):%s",
        vim.inspect(type(remote)),
        vim.inspect(remote)
    )

    --- @type JobResult
    local remote_url_result = git.get_remote_url(remote)
    if not git.result_has_out(remote_url_result) then
        git.result_print_err(
            remote_url_result,
            "failed to get remote url by remote '" .. remote .. "'"
        )
        return nil
    end
    logger.debug(
        "|make_link_data| remote_url_result(%s):%s",
        vim.inspect(type(remote_url_result)),
        vim.inspect(remote_url_result)
    )

    --- @type string|nil
    local rev = git.get_closest_remote_compatible_rev(remote)
    if not rev then
        return nil
    end
    logger.debug(
        "|make_link_data| rev(%s):%s",
        vim.inspect(type(rev)),
        vim.inspect(rev)
    )

    local root = root_result.stdout[1]
    local buf_path_on_root = util.relative_path(root)
    logger.debug(
        "|make_link_data| root(%s):%s, buf_path_on_root(%s):%s",
        vim.inspect(type(root)),
        vim.inspect(root),
        vim.inspect(type(buf_path_on_root)),
        vim.inspect(buf_path_on_root)
    )

    --- @type JobResult
    local file_in_rev_result = git.is_file_in_rev(buf_path_on_root, rev)
    if git.result_has_err(file_in_rev_result) then
        git.result_print_err(
            file_in_rev_result,
            "'"
                .. buf_path_on_root
                .. "' does not exist in remote '"
                .. remote
                .. "'"
        )
        return nil
    end
    logger.debug(
        "|make_link_data| file_in_rev_result(%s):%s",
        vim.inspect(type(file_in_rev_result)),
        vim.inspect(file_in_rev_result)
    )

    local buf_path_on_cwd = util.relative_path()
    logger.debug(
        "|make_link_data| buf_path_on_cwd(%s):%s",
        vim.inspect(type(buf_path_on_cwd)),
        vim.inspect(buf_path_on_cwd)
    )

    if range == nil or range["lstart"] == nil or range["lend"] == nil then
        --- @type LineRange
        range = util.line_range()
        logger.debug(
            "[make_link_data] range(%s):%s",
            vim.inspect(type(range)),
            vim.inspect(range)
        )
    end

    local remote_url = remote_url_result.stdout[1]
    logger.debug(
        "[make_link_data] remote_url(%s):%s",
        vim.inspect(type(remote_url)),
        vim.inspect(remote_url)
    )
    return new_linker(
        remote_url,
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

--- @param option table<string, any>
--- @return string|nil
local function link(option)
    logger.debug("[make_link] before merge, option: %s", vim.inspect(option))
    option = vim.tbl_deep_extend("force", Configs, option or {})
    logger.debug("[make_link] after merge, option: %s", vim.inspect(option))

    local range = nil
    if option["lstart"] ~= nil and option["lend"] ~= nil then
        range = { lstart = option["lstart"], lend = option["lend"] }
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

    if option.action then
        option.action(url)
    end
    if option.message then
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
