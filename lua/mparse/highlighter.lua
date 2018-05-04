-- luacheck: globals vim
vim = vim or {}
local nvim = vim.api or {}

local token = require('mparse.token')
local m_grammar = require('mparse.grammar').m_grammar
local util = require('mparse.util')

local cache = require('mparse.cache')

-- TODO: Generate this automatically at runtime.
local src_id = 25832

local highlighter = {}

-- 1: debug
-- 2: info
local levels = {}
levels.debug = 1
levels.info = 2

highlighter.log_level = levels.info

highlighter.clear_highlights = function(buffer, start, finish)
  nvim.nvim_buf_clear_highlight(buffer, src_id, start, finish)
end

highlighter.clear_all = function(buffer)
  nvim.nvim_buf_clear_highlight(buffer, src_id, 0, -1)
end

highlighter.add_highlight = function(buffer, group, line, start, finish)
  if highlighter.log_level <= levels.debug then
    nvim.nvim_command(string.format('echom "Adding: %s, %d, %d, %d"', group, line, start, finish))
  end

  nvim.nvim_buf_add_highlight(buffer, src_id, group, line, start, finish)
end

highlighter.get_lines = function(buffer)
  return table.concat(nvim.nvim_buf_get_lines(buffer, 0, -1, true), "\n")
end

highlighter.get_ast = function(buffer)
  -- TODO: Maybe someday pass a diff only
  local buf = highlighter.get_lines(buffer)
  return token.parsestring(m_grammar, buf)
end

highlighter.transformer = function(ast, starting_line)
  if type(ast) == 'string' then
    return ast
  end

  if type(ast) ~= 'table' then
    return
  end

  for k, tbl in ipairs(ast) do
    if type(k) == 'number' and type(tbl) == 'table' then
      -- ast[k] = highlighter.transformer(ast[k], starting_line)
      highlighter.transformer(ast[k], starting_line)
    end

    if type(tbl) == 'table' and tbl.pos ~= nil and tbl.pos.line_number ~= nil then
      tbl.pos.line_number = tbl.pos.line_number + starting_line
    end
  end

  return ast
end

highlighter.get_piecewise_ast = function(buffer, start, finish)
  local buf = table.concat(vim.api.nvim_buf_get_lines(buffer, start, finish, false), "\n")

  return token.parse_incremental(m_grammar, buf, highlighter.transformer, start)
end

highlighter.get_highlights = function(buffer)
  -- Clear our caché of where things are located
  cache.clear_cache()

  local ast = highlighter.get_ast(buffer)

  if ast == nil then
    return {}
  end

  local highlights = {}

  highlighter.append_highlights(ast, highlights)

  return highlights
end

highlighter.get_piecewise_highlights = function(buffer, start, finish)
  cache.clear_cache()

  local ast = highlighter.get_piecewise_ast(buffer, start, finish)

  if ast == nil then
    return {}
  end

  local highlights = {}
  highlighter.apply_highlights(ast, highlights)

  return highlights
end

highlighter.append_highlights = function(ast, result)
  if type(ast) == 'string' then
    return result
  end

  if ast.value then
    table.insert(result, {
      value=ast.value,
      pos=ast.pos,
      args=highlighter.convert_pos_to_start_finish(ast.pos),
      id=ast.id,
    })
  end

  for k, _ in pairs(ast) do
    if type(k) == 'number' then
      util.t_concat(result, highlighter.append_highlights(ast[k], result))
    end
  end

  return result
end

highlighter.convert_pos_to_start_finish = function(pos)
  local start_line = pos.line_number

  -- TODO: Figure out what to do if they are on separate lines
  local col_start = pos.column_start
  local col_end = pos.column_finish

  return {
    line = start_line - 1,
    col_start = col_start,
    col_end = col_end + 1,
  }
end

highlighter.apply_highlights = function(buffer)
  highlighter.clear_highlights(buffer, 0, -1)

  local highlights = highlighter.get_highlights(buffer)

  for _, v in pairs(highlights) do
    highlighter.add_highlight(buffer, v.id, v.args.line, v.args.col_start, v.args.col_end)
  end

  return highlights
end

highlighter.apply_piecewise_highlights = function(buffer, start, finish)
  if highlighter.log_level <= levels.info then
    vim.api.nvim_command(string.format('echom "Piecewise highlights for: %s %s"', start, finish))
  end

  highlighter.clear_highlights(buffer, start, finish)

  local highlights = highlighter.get_piecewise_highlights(buffer, start, finish)

  for _, v in pairs(highlights) do
    highlighter.add_highlight(buffer, v.id, v.args.line, v.args.col_start, v.args.col_end)
  end

  return highlights
end

return highlighter
