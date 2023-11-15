local logger = require("gitlinker.logger")
local Linker = require("gitlinker.linker").Linker
local highlight = require("gitlinker.highlight")
local deprecation = require("gitlinker.deprecation")

--- @alias Options table<any, any>
--- @type Options
local Defaults = {
  -- print permanent url in command line
  --
  --- @type boolean
  message = true,

  -- highlight the linked region
  --
  --- @type integer
  highlight_duration = 500,

  -- key mappings
  --
  --- @alias KeyMappingConfig {action:fun(url:string):nil,desc:string?}
  --- @type table<string, KeyMappingConfig>
  mapping = {
    ["<leader>gl"] = {
      router = require("gitlinker.routers").blob,
      action = require("gitlinker.actions").clipboard,
      desc = "Copy git link to clipboard",
    },
    ["<leader>gL"] = {
      router = require("gitlinker.routers").blob,
      action = require("gitlinker.actions").system,
      desc = "Open git link in browser",
    },
  },

  -- enable debug
  --
  --- @type boolean
  debug = false,

  -- write logs to console(command line)
  --
  --- @type boolean
  console_log = true,

  -- write logs to file
  --
  --- @type boolean
  file_log = false,
}

--- @type Options
local Configs = {}

--- @param opts Options
local function deprecated_notification(opts)
  if type(opts) == "table" and opts.pattern_rules ~= nil then
    deprecation.notify(
      "'pattern_rules' is deprecated! please migrate to latest configs."
    )
  end
  if type(opts) == "table" and opts.override_rules ~= nil then
    deprecation.notify(
      "'override_rules' is deprecated! please migrate to latest configs."
    )
  end
  if type(opts) == "table" and opts.custom_rules ~= nil then
    deprecation.notify(
      "'custom_rules' is deprecated! please migrate to latest configs."
    )
  end
end

--- @param opts Options?
local function setup(opts)
  Configs = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), opts or {})

  -- logger
  logger.setup({
    level = Configs.debug and "DEBUG" or "INFO",
    console_log = Configs.console_log,
    file_log = Configs.file_log,
  })

  local key_mappings = nil
  if type(opts) == "table" and opts["mapping"] ~= nil then
    if type(opts["mapping"]) == "table" then
      key_mappings = opts["mapping"]
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
        require("gitlinker").link({ action = v.action, router = v.router })
      end, opt)
    end
  end

  -- Configure highlight group
  if Configs.highlight_duration > 0 then
    local hl_name = "NvimGitLinkerHighlightTextObject"
    if not highlight.hl_group_exists(hl_name) then
      vim.api.nvim_set_hl(0, hl_name, { link = "Search" })
    end
  end

  -- logger.debug("|setup| Configs:%s", vim.inspect(Configs))

  deprecated_notification(Configs)
end

--- @param opts Options?
--- @return string?
local function link(opts)
  opts = vim.tbl_deep_extend("force", vim.deepcopy(Configs), opts or {})
  -- logger.debug("[link] merged opts: %s", vim.inspect(opts))
  deprecated_notification(opts)

  local range = (type(opts.lstart) == "number" and type(opts.lend) == "number")
      and { lstart = opts.lstart, lend = opts.lend }
    or nil
  local lk = Linker:make(range)
  if not lk then
    return nil
  end

  local url = type(opts.router) == "function" and opts.router(lk)
    or require("gitlinker.routers").blob(lk)
  logger.ensure(
    type(url) == "string" and string.len(url) > 0,
    "fatal: failed to generate permanent url from remote url:%s",
    lk.remote_url
  )

  if opts.action then
    opts.action(url)
  end

  if opts.highlight_duration > 0 then
    highlight.show({ lstart = lk.lstart, lend = lk.lend })
    vim.defer_fn(highlight.clear, opts.highlight_duration)
  end

  if opts.message then
    local msg = lk.file_changed
        and string.format("%s (lines can be wrong due to file change)", url)
      or url
    logger.info(msg)
  end

  return url
end

local M = {
  setup = setup,
  link = link,
}

return M
