local epnf = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('mCommands', function()
  describe('mNewCommand', function()
    it('should not detect other commands', function()
      local parsed = epnf.parsestring(m, [[
MyLabel() ;
  q hello
]])
      neq(nil, parsed)
      eq(nil, helpers.get_item(parsed, 'id', 'mNewCommand'))
    end)

    it('should detect new commands', function()
      local parsed = epnf.parsestring(m, [[
MyLabel() ;
  n hello
]])
      neq(nil, parsed)
      neq(nil, helpers.get_item(parsed, 'id', 'mNewCommand'))
    end)
  end)

  describe('mDoCommand', function()
    it('should detect do commands', function()
      local parsed = epnf.parsestring(m, [[
MyLabel() ;
  d functionCall()
]])
      neq(nil, parsed)

      eq('d', helpers.get_item(parsed, 'id', 'mDoCommand').value)
      eq('functionCall', helpers.get_item(parsed, 'id', 'mDoFunctionCall').value)
    end)
  end)
end)

