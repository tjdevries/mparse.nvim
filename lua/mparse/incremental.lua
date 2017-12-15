-- luacheck: globals vim
local vim = vim or {}
local nvim = vim.api or {}

local inc = {}

inc.find_labels = function()
  return nvim.nvim_call_function('mparse#find_labels')
end

-- @param ast: Originally parsed file
-- @param label_lines: The list of lines that labels appear on
-- @param line_number: The current line number
inc.ast_current_label = function(ast, label_lines, line_number)
  local current_label = -1
  for label_index, label_line in ipairs(label_lines) do
    if label_line > line_number then
      current_label = label_index - 1
      break
    end
  end

  if current_label == -1 then
    return {}
  end

  return ast[1][current_label]

  -- Keeping here for now just to remind me to test weird editting scenarios
  -- local str = require('mparse.util').to_string
  -- for index, _ in ipairs(ast) do
  --   for block_index, block in ipairs(ast[_file_index]) do
  --     print('=========================')
  --     print(block.id .. ": " .. block.value)
  --     print(str(block.pos))

  --     if block.pos.line_number > line_number then
  --       found = true
  --       break
  --     end

  --     return_block = block

  --     for label_index, label in ipairs(ast[_file_index][block_index]) do
  --       print(label_index)
  --       print(str(label.id))
  --       print()
  --     end
  --   end

  --   if found then break end
  -- end

  -- return return_block
end

-- TODO: Function to change the positions in an AST.
-- @param ast: Parsed subsection of results
-- @param position_transform (position structure): A table that contains the number to shift positions by
inc.transform_pos = function(ast, _)
  -- print(require('mparse.util').to_string(ast))
  -- print(position_transform)

  -- luacheck: globals table.deepcopy
  require('mparse.deepcopy')
  local transformed = table.deepcopy(ast)

  return transformed
end

return inc
