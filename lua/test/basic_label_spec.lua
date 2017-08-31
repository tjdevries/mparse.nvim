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
    local label = helpers.get_item(parsed, 'id', 'mLabel')
    neq(label, nil)
    eq(label.id, "mLabel")

    local labelName = helpers.get_item(parsed, 'id', 'mLabelName')
    eq(labelName.id, "mLabelName")
    eq(labelName.value, "MyLabel")
    eq(labelName.pos.start, 1)
    eq(labelName.pos.finish, 7)
  end)

  it('should return the name of the label even with comments', function()
    local parsed = epnf.parsestring(m, [[
; We've got a comment here
; We've got another comment here
MyLabel(arg1,arg2) n hello
]])
    local label = helpers.get_item(parsed, 'id', 'mLabel')
    neq(label, nil)
    eq(label.id, "mLabel")

    local labelName = helpers.get_item(parsed, 'id', 'mLabelName')
    eq(labelName.id, "mLabelName")
    eq(labelName.value, "MyLabel")
    eq(labelName.pos.start, 61)
    eq(labelName.pos.finish, 67)
    eq(labelName.pos.line_number, 3)

    local comment = helpers.get_item(parsed, 'id', 'mComment')
    eq(comment.id, "mComment")
    eq(comment.value, "; We've got a comment here")
  end)

  it('should return the name of the label even with a single argument', function()
    local parsed = epnf.parsestring(m, [[
MyLabel(arg1) ;
  n hello
]])
    local label = helpers.get_item(parsed, 'id', 'mLabel')
    neq(label, nil)
    eq(label.id, "mLabel")
  end)

  it('should allow quitting with numbers', function()
    local parsed = epnf.parsestring(m, [[
MyLabel() ;
  w "hello world!"
  q 1
]])
    neq(nil, parsed)
    neq(nil, helpers.get_item(parsed, 'id', 'mQuitCommand'))
    print()
    print(require('mparse.util').to_string(parsed))
    print()
  end)
end)
