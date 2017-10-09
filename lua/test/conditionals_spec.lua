local epnf = require('mparse.token')
local m = require('mparse.grammar').m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('postConditionals', function()
  it('should detect post conditionals', function()
    local parsed = epnf.parsestring(m, [[
myFunction(arg) ;
  n testVar
  d:(arg=1) myFunction(testVar)
  q 2
]])
    neq(nil, parsed)
    local post_conditional = helpers.get_item(parsed, 'id', 'mPostConditional')
    neq(nil, post_conditional)
    eq(':', post_conditional[1].value)
  end)

  it('should detect until whitespace', function()
    local parsed = epnf.parsestring(m, [[
myFunction(arg) ;
  n testVar
  d:(arg=1)!(arg="") myFunction(testVar)
  q 2
]])
    neq(nil, parsed)
    local post_conditional = helpers.get_item(parsed, 'id', 'mPostConditional')
    neq(nil, post_conditional)
  end)

  it('should handle simple values', function()
    local parsed = epnf.parsestring(m, [[
myFunc() ;
  n var
  d:1 myOtherFunc()
  q
]])
    neq(nil, parsed)
    local post_conditional = helpers.get_item(parsed, 'id', 'mPostConditional')
  end)

  it('should handle function calls', function()
    local parsed = epnf.parsestring(m, [[
myFunc() ;
  n var
  d:$$test() myOtherFunc()
  q
]])
    neq(nil, parsed)
    local post_conditional = helpers.get_item(parsed, 'id', 'mPostConditional')
    eq('test', helpers.get_item(post_conditional, 'id', 'mDoFunctionCall').value)
  end)

  it('should handle a comparison without parenths', function()
    local parsed = epnf.parsestring(m, [[
myFunc(var) ;
  d:var=1 myOtherFunc()
  q
]])
    neq(nil, parsed)
    local post_conditional = helpers.get_item(parsed, 'id', 'mPostConditional')
    neq(nil, post_conditional)
  end)
end)
