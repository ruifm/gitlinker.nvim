--- @param fmt string
--- @param ... any
local function notify(fmt, ...)
  fmt = "[gitlinker] warning! " .. fmt
  local msg = string.format(fmt, ...)
  local function impl()
    local chunks = { { msg, "WarningMsg" } }
    vim.api.nvim_echo(chunks, false, {})
  end

  vim.schedule(impl)
  vim.defer_fn(impl, 3000)
end

local M = {
  notify = notify,
}

return M
