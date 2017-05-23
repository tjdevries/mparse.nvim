local nvim = vim.api

local epnf = require '../src.token'
local m_grammar = require('../src.grammar').m_grammar
local util = require '../src.util'

local src_id = 25832

clear_highlights = function(buffer, start, finish)
  nvim.nvim_buf_clear_highlight(buffer, src_id, start, finish)
end

clear_all = function(buffer)
  nvim.nvim_buf_clear_highlight(buffer, src_id, 0, -1)
end

add_highlight = function(buffer, group, line, start, finish)
  nvim.nvim_buf_add_highlight(buffer, src_id, group, line, start, finish)
end

get_ast = function(buffer)
  -- TODO: Maybe someday pass a diff only
  local buf = table.concat(nvim.nvim_buf_get_lines(buffer, 0, -1, true), "\n")
  return epnf.parsestring(m_grammar, buf)
end

get_highlights = function(buffer)
  local ast = get_ast(buffer)

  local highlights = {}

  append_highlights(ast, highlights)

  return highlights
end

append_highlights = function(ast, result)
  if type(ast) == 'string' then
    return result
  end

  if ast.value then
    table.insert(result, {
      value=ast.value,
      pos=ast.pos,
      args=convert_pos_to_start_finish(ast.pos),
      id=ast.id,
    })
  end

  for k, v in pairs(ast) do
    if type(k) == 'number' then
      util.t_concat(result, append_highlights(ast[k], result))
    else
    end
  end

  return result
end

convert_pos_to_start_finish = function(pos)
  local s = pos.start
  local f = pos.finish

  -- TODO: Cache these values, as well as the line2byte values
  -- This should dramatically reduce the number of RPC calls that I need to make
  -- especially considering that so many of the calls occur for items on the same line. 
  local start_line = nvim.nvim_call_function('byte2line', {s})
  local finish_line = nvim.nvim_call_function('byte2line', {f})

  -- TODO: Figure out what to do if they are on separate lines
  local start_line_byte = nvim.nvim_call_function('line2byte', {start_line})
  local col_start = s - start_line_byte
  local col_end = f - start_line_byte

  return {
    line=start_line - 1,
    col_start=col_start,
    col_end=col_end + 1,
  }
end

apply_highlights = function(buffer)
  clear_highlights(buffer, 0, -1)

  local highlights = get_highlights(buffer)

  for k, v in pairs(highlights) do
    add_highlight(buffer, v.id, v.args.line, v.args.col_start, v.args.col_end)
  end

  return highlights
end
