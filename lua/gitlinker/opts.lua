return {
  remote = nil, -- force the use of a specific remote
  add_current_line_on_normal_mode = true, -- if true adds the line nr in the url for normal mode
  action_callback = require"gitlinker.actions".copy_to_clipboard, -- callback for what to do with the url
  mappings = "<leader>gy",
  print_url = true -- print the url after action
}
