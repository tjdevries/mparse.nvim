

local epnf = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('Do Command is difficult', function()
  it('should handle adding a dot-level 1', function()
    local parsed = epnf.parsestring(m, [[
testLab() ;
  d
  . w "HELLO"
  q
]])
    neq(nil, parsed)
    eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
    eq('"HELLO"', helpers.get_item(parsed, 'id', 'mString').value)
  end)
end)
