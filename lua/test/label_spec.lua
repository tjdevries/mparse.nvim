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
  it('should detect ^ as globals', function()
    local parsed = epnf.parsestring(m, [[
labl() ;
  s ^XEXAMPLE=10
  q 1
]])
    neq(nil, parsed)
    eq('^XEXAMPLE', helpers.get_item(parsed, 'id', 'mVariable').value)
  end)
  it('should detect ^...() as globals', function()
    local parsed = epnf.parsestring(m, [[
labl() ;
  s ^XEXAMPLE("abc")=10
  q 1
]])
    neq(nil, parsed)
    eq('^XEXAMPLE("abc")', helpers.get_item(parsed, 'id', 'mVariable').value)
  end)
  it('should detect $J as variables (intrinsics)', function()
    local parsed = epnf.parsestring(m, [[
labl() ;
  s job=$J
  q 1
]])
    neq(nil, parsed)
    eq('job', helpers.get_item(parsed, 'id', 'mVariable').value)
    eq('$J', helpers.get_item(parsed, 'id', 'mVariableIntrinsic').value)
  end)
  describe('[Command Detection]', function()
    describe('Do command ==>', function()
      it('should notice function calls for do functions without $$', function()
        local parsed = epnf.parsestring(m, [[
; comment
testLabel ; comment
  d main^TESTTAG()
]])

        local do_func = helpers.get_item(parsed, 'id', 'mDoFunctionCall')
        neq(nil, do_func)
      end)
      it('should allow string concatenation in the call', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d myFunc("concatenate"_myVar)
]])
        neq(nil, parsed)
        neq(nil, helpers.get_item(parsed, 'id', 'mDoFunctionCall'))
        eq('myFunc', helpers.get_item(parsed, 'id', 'mDoFunctionCall').value)
      end)
      it('should allow addition in the call', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d myFunc(firstVar+myVar+"hello"+3)
]])
        neq(nil, parsed)
        neq(nil, helpers.get_item(parsed, 'id', 'mDoFunctionCall'))
        eq('myFunc', helpers.get_item(parsed, 'id', 'mDoFunctionCall').value)
      end)
      it('should allow relationals in the call', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d myFunc(myVar<thatVar)
  q
]])
        neq(nil, parsed)
        neq(nil, helpers.get_item(parsed, 'id', 'mDoFunctionCall'))
      end)
      it('should allow dotted references in the call', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d myFunc(.myVar)
  q
]])
        neq(nil, parsed)
        neq(nil, helpers.get_item(parsed, 'id', 'mDoFunctionCall'))
      end)
      it('should allow equals in the call', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d myFunc(1=2,"hello")
  q
]])
        neq(nil, parsed)
      end)
      it('should allow conditionals in the call', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d myFunc(1=2:"hello",1:"goodbye")
  q
]])
        neq(nil, parsed)
      end)
      it('should allow blank commas in the call', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d myFunc("hello",,"world")
  q
]])
        neq(nil, parsed)
      end)
      it('should allow secondary commands', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d  w "this thing"
  . w !,"HELLO WORLD"
  q
]])
        neq(nil, parsed)
        eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      end)
      it('should allow secondary quit commands', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d  q:(1=1) 1
  . w !,"HELLO WORLD"
  q
]])
        neq(nil, parsed)
        eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      end)
      it('should allow secondary quit commands with no args', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d  q
  . w !,"HELLO WORLD"
  q
]])
        neq(nil, parsed)
        eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      end)
      it('should allow secondary quit commands with a conditional', function()
        local parsed = epnf.parsestring(m, [[
doLabel() ;
  d  q:(1=1)
  . w !,"HELLO WORLD"
  q
]])
        neq(nil, parsed)
        eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      end)
    end)
    describe('New command ==>', function()
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
        local command = helpers.get_item(parsed, 'id', 'mNewCommand')
        neq(nil, command)

        local err = helpers.get_item(command, 'id', 'mCapturedError')
        neq(nil, err)
        eq('$$errorFunction()', err.value)
        eq(#'$$errorFunction()', err.pos.finish - err.pos.start + 1)
      end)
      it('should show an error for only calling functions', function()
        local parsed = epnf.parsestring(m, [[
testLabel ; comment
  n $$errorFunction()
  q
]])
        local command = helpers.get_item(parsed, 'id', 'mNewCommand')
        neq(nil, command)

        local err = helpers.get_item(command, 'id', 'mCapturedError')
        neq(nil, err)
        eq('$$errorFunction()', err.value)
        eq(#'$$errorFunction()', err.pos.finish - err.pos.start + 1)
      end)
      it('should show an error for newing numbers', function()
        local parsed = epnf.parsestring(m, [[
testLabel ; comment
  n myVar,5
  q
]])
        local command = helpers.get_item(parsed, 'id', 'mNewCommand')
        neq(nil, command)

        local err = helpers.get_item(command, 'id', 'mCapturedError')
        neq(nil, err)
        eq('5', err.value)
        eq(#'5', err.pos.finish - err.pos.start + 1)
      end)
      it('should not show an error for newing vars with numbers', function()
        local parsed = epnf.parsestring(m, [[
testLabel ; comment
  n myVar5
  q
]])
        local command = helpers.get_item(parsed, 'id', 'mNewCommand')
        neq(nil, command)

        local err = helpers.get_item(command, 'id', 'mCapturedError')
        eq(nil, err)
      end)
      it('should show an error for newing vars that start with numbers', function()
        local parsed = epnf.parsestring(m, [[
testLabel ; comment
  n 5myVar5
  q
]])
        local command = helpers.get_item(parsed, 'id', 'mNewCommand')
        neq(nil, command)

        local err = helpers.get_item(command, 'id', 'mCapturedError')
        neq(nil, err)
        eq('5myVar5', err.value)
        eq(#'5myVar5', err.pos.finish - err.pos.start + 1)
      end)
    end)
    describe('Set Command ==>', function()
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
  ; another comment ; comments () "" %$
BasicTest(opt) ;
    w "hello"_" new world "_opt
]])
        neq(nil, parsed)
        local command = helpers.get_item(parsed, 'id', 'mWriteCommand')
        eq('"hello"', helpers.get_item(command, 'id', 'mString').value)
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
      it('should handle arithmetic items', function()
        local parsed = epnf.parsestring(m, [[
myLabel() ; a comment
    w 1+5
]])
        neq(nil, parsed)
      end)
      it('should handle zw as a write command', function()
        local parsed = epnf.parsestring(m, [[
myLabel() ; comment
  zw myArray
]])
        neq(nil, parsed)
        eq('zw', helpers.get_item(parsed, 'id', 'mWriteCommand').value)
      end)
      it('should handle using operators and numbers', function()
        local parsed = epnf.parsestring(m, [[
writeDictionaryItem(itemID,itemValue) ;
 w !,itemID,?10,": ",$p(itemValue,"^",1,1),?60,$p(itemValue,"^",2,2)
 q
]])
        neq(nil, parsed)
        eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      end)
    end)
    describe('If Command ==>', function()
      it('should handle numbers', function()
        local parsed = epnf.parsestring(m, [[
IfLabel() ;
  i 1 w "true"
  q
]])
        neq(nil, parsed)
      end)
      it('should handle addition', function()
        local parsed = epnf.parsestring(m, [[
IfLabel2() ;
  i myVar+23 w "TRUE"
  q
]])
        neq(nil, parsed)
      end)
    end)
    describe('Quit Command ==>', function()
      it('should handle one letter functions', function()
        local parsed = epnf.parsestring(m, [[
QuitLabel(myVar) q $d(myVar)
]])
        neq(nil, parsed)
        neq(nil, helpers.get_item(parsed, 'id', 'mFunctionCall'))
      end)
      it('should handle functions with conditionals', function()
        local parsed = epnf.parsestring(m, [[
QuitLabel() q $s(0:"nope",1:"yup")
]])
        neq(nil, parsed)
        neq(nil, helpers.get_item(parsed, 'id', 'mFunctionCall'))
      end)
      it('should handle adding functions', function()
        local parsed = epnf.parsestring(m, [[
QuitLabel() q $$func1()+$$func2()
]])
        neq(nil, parsed)
      end)
    end)
    describe('For Command ==>', function()
      it('Should handle one line for functions', function()
        local parsed = epnf.parsestring(m, [[
TestLabel() f idx=1:1:100 w !,idx
  q
]])
        neq(nil, parsed)
        eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      end)
      it('Should handle multi-line do functions', function()
        local parsed = epnf.parsestring(m, [[
TestLabel() f idx=1:1:100 d
  . w !,"hello"
  . w !,"yup"
  q
]])
        neq(nil, parsed)
        eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      end)
      it('Should handle set stuff and then do functions', function()
        local parsed = epnf.parsestring(m, [[
TestLabel() ;
  f  s idx=$$nextID(idx) d
  . w !,"hello"
  q
]])
        neq(nil, parsed)
        eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      end)
      it('Should handle set, quit and then do functions', function()
        local parsed = epnf.parsestring(m, [[
TestLabel() ;
  f  s idx=$$nextID(idx) q:idx=""  d
  . w !,"hello"
  q 1
]])
        neq(nil, parsed)
        eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      end)
      it('Should handle set, quit and then do functions', function()
        local parsed = epnf.parsestring(m, [[
TestLabel() ;
  f  s idx=$$nextID(idx) q:(idx="")  d
  . w !,"This is a for loop"
  n myVar
  q
]])
        neq(nil, parsed)
        eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      end)
    end)
  end)
  describe('[Realistic Examples]', function()
    it('should work 1', function()
      local parsed = epnf.parsestring(m, [[
Example(var) ;;#testTag# It can handle compiler directives
  n factor,idx
  ; It knows about intrinsics!
  s factor($J)=$$setDefault(0,factor("NOT A THING"),"default")
  ;]] .. "\r\n" .. [[; Handles intrinsic functions and user functions
  d thisFunction()
  q
]])
      neq(nil, parsed)
      eq(nil, helpers.get_item(parsed, 'id', 'mCapturedError'))
      eq('thisFunction', helpers.get_item(helpers.get_item(parsed, 'id', 'mDoCommand'), 'id', 'mDoFunctionCall').value)
    end)
  end)
end)
