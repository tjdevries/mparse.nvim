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
    local post_conditional = helpers.get_item(parsed, 'id', 'mPostConditional')
    print()
    print(require('mparse.util').to_string(parsed))
    print()
    neq(nil, post_conditional)
    eq(nil, post_conditional)
  end)

  it('should detect until whitespace', function()
    local parsed = epnf.parsestring(m, [[
myFunction(arg) ;
  n testVar
  d:(arg=1)!(arg="") myFunction(testVar)
  q 2
]])
    local post_conditional = helpers.get_item(parsed, 'id', 'mPostConditional')
    neq(nil, post_conditional)

  end)
end)
