local epnf = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('indirection:', function()
  it('should handle setting a value with indirection', function()
    local parsed = epnf.parsestring(m, [[
  ; a comment
mySetter() ;
  s myVar=@indirect
  q
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
  end)

  it('should handle setting a value with array indirection', function()
    local parsed = epnf.parsestring(m, [[
  ; a comment
mySetter() ;
  s myVar=@"MYGLOBAL"@("sub")
  q
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq(nil, helpers.get_item(parsed, 'id', 'mVariableIndirect'))
    print()
    print(require('mparse.util').to_string(parsed))
    print()
  end)

  it('should handle setting a value with with parenths inside', function()
    local parsed = epnf.parsestring(m, [[
  ; a comment
mySetter() ;
  s myVar=@(indirect_"suffix")
  q
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    neq(nil, helpers.get_item(parsed, 'id', 'mVariableIndirect'))
  end)
end)
