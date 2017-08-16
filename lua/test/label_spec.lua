local epnf = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('mLabel:', function()
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
    eq(labelName.value, "MyCommentedLabel")
    eq(labelName.pos.start, 32)
    eq(labelName.pos.finish, 47)
    eq(labelName.pos.line_number, 2)
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
    neq(nil, arguments)
    eq('arg1', arguments[1].value)
    eq('arg2', arguments[2].value)

    local command = helpers.get_item(parsed, 'id', 'mWriteCommand')
    neq(nil, command)
    eq(command.value, 'w')

    local s = helpers.get_item(command, 'id', 'mString')
    eq(s.value, '"this will be a mArgumentReference"')
    eq(s.pos.start, 84)
    eq(s.pos.finish, 118)
    eq(s.pos.line_number, 3)

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
    local command = helpers.get_item(parsed, 'id', 'mNewCommand')
    neq(nil, command)
    eq(command.value, 'n')

    local commandArgs = helpers.get_item(command, 'id', 'mNewCommandArgs')
    eq(commandArgs.id, 'mNewCommandArgs')

    local notParam = helpers.get_item(commandArgs, 'id', 'mVariable')
    neq(notParam, nil)
    neq(notParam.id, 'mParameter')
    eq(notParam.value, 'notParameter')
    eq(notParam.id, 'mVariable')
  end)

  it('should get lowercased labels', function()
    local parsed = epnf.parsestring(m, [[
; doesn't matter
getLowerCase(arg) ; comment
  n yup
  s yup=1
  w arg,yup
  q yup
]])
    local label = helpers.get_item(parsed, 'id', 'mLabelName')
    eq(label.value, 'getLowerCase')
  end)

  it('should detect labels without arguments', function()
    local parsed = epnf.parsestring(m, [[
; just a comment
testLabel ; comment
  n just,do,stuff,here
  w just,do,stuff,here
]])
    local label = helpers.get_item(parsed, 'id', 'mLabelName')
    neq(nil, label)
    -- eq(label.value, 'testLabel')
  end)

  describe('[Command Detection]', function()
    describe('do command', function()
      it('should notice function calls for do functions without $$', function()
        local parsed = epnf.parsestring(m, [[
; comment
testLabel ; comment
  d main^TESTTAG()
]])

        local do_func = helpers.get_item(parsed, 'id', 'mDoFunctionCall')
        neq(nil, do_func)
      end)
    end)

    describe('new command', function()
      it('should allow for defining variables', function()
        local parsed = epnf.parsestring(m, [[
testLabel ; comment
  n myVar,otherVar
  q
]])
        local command = helpers.get_item(parsed, 'id', 'mNewCommand')
        neq(nil, command)

        local var = helpers.get_item(command, 'id', 'mVariable')
        neq(nil, var)
        eq(var.value, 'myVar')

        eq(nil, helpers.get_item(command, 'id', 'mCapturedError'))
      end)

      it('should show an error for calling functions', function()
        local parsed = epnf.parsestring(m, [[
testLabel ; comment
  n myVar,$$errorFunction()
  q
]])

    print()
    print(require('mparse.util').to_string(parsed))
    print()
        local command = helpers.get_item(parsed, 'id', 'mNewCommand')
        neq(nil, command)

        local err = helpers.get_item(command, 'id', 'mCapturedError')
        neq(nil, err)
        eq(',$$errorFunction()', err.value)
        eq(#',$$errorFunction()', err.pos.finish - err.pos.start + 1)
      end)
    end)

    describe('set command', function()
      it('should be found when using the set command', function()
        local parsed = epnf.parsestring(m, [[
testLabel ; comment
  s myVar=1
  q
]])
        local command = helpers.get_item(parsed, 'id', 'mSetCommand')
        neq(nil, command)

        eq(nil, helpers.get_item(command, 'id', 'mCapturedError'))
      end)

      it('should be found when using the set command and adding a number', function()
        local parsed = epnf.parsestring(m, [[
testLabel ; comment
  s myVar=1+2
  q
]])
        local command = helpers.get_item(parsed, 'id', 'mSetCommand')
        neq(nil, command)
        eq(nil, helpers.get_item(command, 'id', 'mCapturedError'))
      end)

      it('should be found when using the set command and adding a function', function()
        local parsed = epnf.parsestring(m, [[
testLabel ; comment
  s myVar=1+$$helloWorld()
  q
]])
        local command = helpers.get_item(parsed, 'id', 'mSetCommand')
        neq(nil, command)
        neq(nil, helpers.get_item(command, 'id', 'mFunctionCall'))
        neq(nil, helpers.get_item(command, 'id', 'mDoFunctionCall'))
        neq(nil, helpers.get_item(command, 'id', 'mDigit'))

        eq(nil, helpers.get_item(command, 'id', 'mCapturedError'))
      end)

      it('should find errors when using set command incorrectly', function()
        local parsed = epnf.parsestring(m, [[
testLabel ; comment
  s $$myVar()=1+$$helloWorld()
  q
]])
        local command = helpers.get_item(parsed, 'id', 'mSetCommand')
        neq(nil, command)
        neq(nil, helpers.get_item(command, 'id', 'mCapturedError'))
      end)
    end)

    describe('Write Command ==>', function()
      it('should handle multiple operators', function()
        local parsed = epnf.parsestring(m, [[
BasicTest(opt) ;
    w "hello",!,"new line",5!
]])
        neq(nil, parsed)
        neq(nil, helpers.get_item(parsed, 'id', 'mWriteCommand'))
        neq(nil, helpers.get_item(parsed, 'id', 'mCommandOperator'))
        eq('!', helpers.get_item(parsed, 'id', 'mCommandOperator').value)
      end)

      it('should handle concatenation', function()
        local parsed = epnf.parsestring(m, [[
BasicTest(opt) ;
    w "hello"_" new world "_opt
]])
        neq(nil, parsed)
        local command = helpers.get_item(parsed, 'id', 'mWriteCommand')
        neq(nil, helpers.get_item(command, 'id', 'mConcatenationOperators'))
      end)

      it('should handle other commands with it', function()
        local parsed = epnf.parsestring(m, [[
myLabel() ; a comment
    n myVar
    w "This or that"
    q myVar
]])
        neq(nil, parsed)
      end)
    end)
  end)
end)
