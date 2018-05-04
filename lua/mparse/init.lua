local highlighter = require('mparse.highlighter')
local incremental = require('mparse.incremental')

local plugin = {}

plugin.highlight = function()
  return highlighter.apply_highlights(0)
end

plugin.find_labels = function()
  return incremental.find_labels()
end

plugin.piecewise_highlight = function()
  local function_lines = vim.api.nvim_call_function('mparse#find_labels', {})

  local highlights = {}
  for index, line in pairs(function_lines) do
    local end_index
    if index ~= #function_lines then
      end_index = function_lines[index + 1]
    else
      vim.api.nvim_command('echom "Last Line"')
      end_index = vim.api.nvim_buf_line_count(0) - 1
    end

    -- _, highlights = pcall(function()
    --   highlighter.apply_piecewise_highlights(0, line - 1, end_index)
    -- end)
    table.insert(highlights, highlighter.apply_piecewise_highlights(0, line - 1, end_index))
  end

  return highlights
end

return plugin
