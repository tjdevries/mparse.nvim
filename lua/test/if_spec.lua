
local epnf = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('If Command is difficult', function()
  it('should handle dot-levels 1', function()
    local parsed = epnf.parsestring(m, [[
testLabel() ;
  i 1 d
  . w "Success"
  q
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq('"Success"', helpers.get_item(parsed, 'id', 'mString').value)
  end)
  it('should handle dot-levels 2', function()
    local parsed = epnf.parsestring(m, [[
testLabel() ;
  i 1 d
  . w "Success"
  . w "Another"
  q
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq('"Success"', helpers.get_item(parsed, 'id', 'mString').value)
  end)
  it('should handle dot-levels 3', function()
    local parsed = epnf.parsestring(m, [[
testLabel() ;
  i 1 d
  . w "Success"
  . w "Another"
  . i 2 w !,"THIS"
  q
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq('"Success"', helpers.get_item(parsed, 'id', 'mString').value)
  end)
  it('should handle a single statements (with parenths)', function()
    local parsed = epnf.parsestring(m, [[
testLabl() ;
  i (option=4) w "HELLO"
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq('w', helpers.get_item(parsed, 'id', 'mWriteCommand').value)
  end)
  it('should handle a single statements (without parenths)', function()
    local parsed = epnf.parsestring(m, [[
testLabl() ;
  i option=4 w "HELLO"
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq('w', helpers.get_item(parsed, 'id', 'mWriteCommand').value)
  end)
  it('should handle multiple statements (without parenths)', function()
    local parsed = epnf.parsestring(m, [[
testLabl() ;
  i option=4,other=10 w "HELLO"
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq('w', helpers.get_item(parsed, 'id', 'mWriteCommand').value)
  end)
  it('should handle multiple statements (with parenths)', function()
    local parsed = epnf.parsestring(m, [[
testLabl() ;
  i (option=4),(other=10) w "HELLO"
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq('w', helpers.get_item(parsed, 'id', 'mWriteCommand').value)
  end)
  it('should handle multiple statements (with extra parenths)', function()
    local parsed = epnf.parsestring(m, [[
testLabl() ;
  i ((option=4),(other=10)) w "HELLO"
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq('w', helpers.get_item(parsed, 'id', 'mWriteCommand').value)
  end)
end)
