local epnf = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq


describe('labelName', function()
  it('should work for good stuff', function()
    neq(nil, epnf.parsestring(m.mLabelName, 'MyLabel'))
  end)

  it('should not accept ()', function()
    neq(nil, epnf.parsestring(m.mLabelName, 'MyLabel()'))
  end)
end)

describe('basic mLabel', function()
  it('should not return anything for non labels', function()
    neq('mLabel', helpers.get_first_item(epnf.parsestring(m, [[
; not a label
]]))
    )
  end)

  it('should return the name of the label', function()
    local parsed = epnf.parsestring(m, [[
MyLabel(arg1,arg2) n hello
]])
    print()
    print(require('mparse.util').to_string(parsed))
    print()
    local label = helpers.get_item(parsed, 'id', 'mLabel')
    neq(label, nil)
    eq(label.id, "mLabel")
    eq(label.value, nil)

    local labelName = helpers.get_item(parsed, 'id', 'mLabelName')
    eq(labelName.id, "mLabelName")
    eq(labelName.value, "MyLabel")
    eq(labelName.pos, {start=1, finish=7})

    local commentItem = helpers.get_item(parsed, 'id', 'mComment')
    eq(commentItem.value, '; This is a comment')
    eq(commentItem.pos, {start=20, finish=38})

    -- eq(parsed[3], "...")
  end)


end)