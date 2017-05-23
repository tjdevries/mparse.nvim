local lpeg = require('lpeg')

local epnf = require('src.token')

local grammar = require('src.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('mLabel', function()
  it('should not return anything for non labels', function()
    neq('mLabel', helpers.get_first_item(epnf.parsestring(m, [[
; not a label
]]))
    )
  end)

  it('should return the name of the label', function()
    local parsed = epnf.parsestring(m, [[
MyLabel(arg1,arg2) ; This is a comment
  q "final"
]])
    local label = helpers.get_item(parsed, 'id', 'mLabel')
    neq(label, nil)
    eq(label.id, "mLabel")
    eq(label.value, nil)

    local labelName = helpers.get_item(parsed, 'id', 'mLabelName')
    eq(labelName.id, "mLabelName")
    eq(labelName.pos, {start=1, finish=7})
    eq(labelName.value, "MyLabel")

    local commentItem = helpers.get_item(parsed, 'id', 'mComment')
    eq(commentItem.value, '; This is a comment')
    eq(commentItem.pos, {start=20, finish=38})

    -- eq(parsed[3], "...")
  end)

  it('should return then ast even with comments before it', function()
    local parsed = epnf.parsestring(m, [[
; this shoudn't mess things up
MyCommentedLabel(arg1,arg2) ; This is a comment
  q "final"
]])
    local label = helpers.get_item(parsed, 'id', 'mLabel')
    neq(label, nil)
    eq(label.id, "mLabel")
    eq(label.value, nil)

    local labelName = helpers.get_item(parsed, 'id', 'mLabelName')
    eq(labelName.id, "mLabelName")
    eq(labelName.pos, {start=32, finish=47})
    eq(labelName.value, "MyCommentedLabel")
  end)

  it('should find the arguments inside of the label', function()
    local parsed = epnf.parsestring(m, [[
; this shoudn't mess things up
MyCommentedLabel(arg1,arg2) ; This is a comment
  w "this will be a mArgumentReference",arg1
  n notParameter
  w arg2,notParameter
  q
]])
    local arguments = helpers.get_item(parsed, 'id', 'mArgumentDeclaration')
    eq(arguments.value, {'arg1', 'arg2'})
    eq(arguments.pos, {start=48, finish=56})

    local command = helpers.get_item(parsed, 'id', 'mCommand')
    eq(command.value, 'w')

    local s = helpers.get_item(command, 'id', 'mString')
    eq(s.value, '"this will be a mArgumentReference"')
    eq(s.pos, {start=84, finish=118})

    if grammar.parameters_enabled then
      local param = helpers.get_item(command, 'id', 'mParameter')
      eq(param.id, 'mParameter')
      eq(param.value, 'arg1')
      eq(param.pos, {start=120, finish=123})
    end
  end)

  it('should not think everything is a parameter', function()
    local parsed = epnf.parsestring(m, [[
; this shoudn't mess things up
MyCommentedLabel(arg1,arg2) ; This is a comment
  n notParameter
  w arg2,notParameter
  q
]])
    local command = helpers.get_item(parsed, 'id', 'mCommand')
    eq(command.value, 'n')

    local commandArgs = helpers.get_item(command, 'id', 'mCommandArgs')
    eq(commandArgs.id, 'mCommandArgs')

    local notParam = helpers.get_item(commandArgs, 'id', 'mVariable')
    neq(notParam, nil)
    neq(notParam.id, 'mParameter')
    eq(notParam.value, 'notParameter')
    eq(notParam.id, 'mVariable')
  end)
end)
