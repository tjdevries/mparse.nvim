-- luacheck: globals vim
local vim = vim or {}
local nvim = vim.api or {}

local inc = {}

local str = require('mparse.util').to_string

inc.find_labels = function()
  return nvim.nvim_call_function('mparse#find_labels')
end

inc.ast_current_label = function(ast, label_lines, line_number)
  local found = false
  local return_block = nil
  for _file_index, _file in ipairs(ast) do
    for block_index, block in ipairs(ast[_file_index]) do
      print('=========================')
      print(block.id .. ": " .. block.value)
      print(str(block.pos))

      if block.pos.line_number > line_number then
        found = true
        break
      end

      return_block = block

      for label_index, label in ipairs(ast[_file_index][block_index]) do
        print(label_index)
        print(str(label.id))
        print()
      end
    end

    if found then break end
  end

  return return_block
end

-- TODO: Function to change the positions in an AST.
inc.transform_pos = function(ast, position_transform)
end

return inc
