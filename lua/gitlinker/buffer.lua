local M = {}

local api = vim.api
local path = require("plenary.path")

function M.get_relative_path(cwd)
  return path:new(api.nvim_buf_get_name(0)):make_relative(cwd)
end

function M.get_curr_line()
  return api.nvim_win_get_cursor(0)[1]
end

function M.get_range(mode, add_current_line_on_normal_mode)
  local lstart
  local lend
  if mode == "v" then
    local pos1 = vim.fn.getpos("v")[2]
    local pos2 = vim.fn.getcurpos()[2]
    lstart = math.min(pos1, pos2)
    lend = math.max(pos1, pos2)
  elseif add_current_line_on_normal_mode == true then
    lstart = M.get_curr_line()
  end

  return { lstart = lstart, lend = lend }
end

--[[
Highlights the text selected by the specified range.
]]
M.highlight_range = function(range)
  local namespace = vim.api.nvim_create_namespace("NvimGitLinker")
  local lstart, lend = range.lstart, range.lend
  if lend and lend < lstart then
    lstart, lend = lend, lstart
  end
  local pos1 = { lstart - 1, 1 }
  local pos2 = { (lend or lstart) - 1, vim.fn.col("$") }
  vim.highlight.range(
    0,
    namespace,
    "NvimGitLinkerHighlightTextObject",
    pos1,
    pos2,
    { inclusive = true }
  )
  -- Force the screen to highlight the text immediately
  vim.cmd("redraw")
end

--[[
Clears the gitlinker highlights for the buffer.
]]
M.clear_highlights = function()
  local namespace = vim.api.nvim_create_namespace("NvimGitLinker")
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
  -- Force the screen to clear the highlight immediately
  vim.cmd("redraw")
end
return M
