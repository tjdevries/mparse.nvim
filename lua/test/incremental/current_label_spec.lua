local token = require('mparse.token')

local incremental = require('mparse.incremental')
local m = require('mparse.grammar').m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('Incremental parser', function()
  describe('[ast_current_label]', function()
    local m_file = [[
MyLabel() ;
  q 1
MyOtherLabel(asdf) ;
  n helloWorld
  w helloWorld,1
  q 1
FinalLabel() ;
  w "wow!"
  q 1
]]
    local label_lines = { 1, 3, 7 }
    it('should find the current label', function()
      local ast = token.parsestring(m, m_file)
      neq(nil, ast)

      local label = incremental.ast_current_label(ast, label_lines, 4)
      eq('MyOtherLabel', label[1].value)
    end)
  end)

  describe('[transform_pos]', function()
    it('should do nothing when passed an empty dictionary', function()
      local partial_file = [[
IncLabel() ;
  q 5
]]
      local ast = token.parsestring(m, partial_file)
      local transformed = incremental.transform_pos(ast, {})
      eq(ast, transformed)
    end)

    it('should add the line numbers when requested', function()
      local partial_file = [[
IncLabel() ;
  q 5
]]

     local ast = token.parse_incremental(m, partial_file, require('mparse.highlighter').transformer, 10)
     eq(ast[1].pos.line_number, 11)
    end)
  end)
end)
