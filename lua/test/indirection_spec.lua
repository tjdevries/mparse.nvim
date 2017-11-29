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
mySetter() s myVar=@"MYGLOBAL"@("sub")
]])
    print()
    print(require('mparse.util').to_string(parsed))
    print()
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq(nil, helpers.get_item(parsed, 'id', 'mVariableIndirect'))
    eq('@"MYGLOBAL"@("sub")', helpers.get_item(parsed, 'id', 'mVariableArray').value)
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
  it('should handle using a function to array indirect', function()
    local parsed = epnf.parsestring(m, [[myTestSetter() s myVar=@$$aFunctionCall()@("hello")]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq(nil, helpers.get_item(parsed, 'id', 'mVariableIndirect'))
    eq('$$aFunctionCall()', helpers.get_item(parsed, 'id', 'mFunctionCall').value)
  end)
  it('should handle using a function with arguments to array indirect', function()
    local parsed = epnf.parsestring(m, [[myTestSetter() s myVar=@$$aFunctionCall("a","b")@("hello")]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq(nil, helpers.get_item(parsed, 'id', 'mVariableIndirect'))
    eq('$$aFunctionCall("a","b")', helpers.get_item(parsed, 'id', 'mFunctionCall').value)
  end)
end)
