local c = require('colorbuddy.init').colors

local Group = require('colorbuddy.init').Group
local g = require('colorbuddy.init').groups

local s = require('colorbuddy.init').styles


Group.new('mCommand', g.statement, g.statement, g.statement)
for _, v in ipairs({'Do', 'Write', 'New', 'Normal', 'Set', 'Quit', 'If', 'For'}) do
    Group.new(string.format('m%sCommand', v), g.mCommand, g.mCommand, g.mCommand)
end

Group.new('mCommandOperator', g.operator, g.operator, g.operator)
Group.new('mSetCommandOperator', g.mCommandOperator, g.mCommandOperator, g.mCommandOperator)

Group.new('mVariable', c.blue:light(.1))
Group.new('mVariableArray', g.mVariable)
Group.new('mVariableNonArray', g.mVariable)
Group.new('mVariableIndirect', g.mVariable)
Group.new('mVariableIntrinsic', g.mVariable.fg:light(.1), nil, s.bold)
Group.new('mIndirectionOperator', c.red, c.none, s.bold)

Group.new('mParameter', c.blue, nil, s.bold)

Group.new('mCommentText', g.Comment, nil, s.italic)
Group.new('mCommentSemiColon', g.Comment, nil, s.none)
Group.new('mCompilerDirective', g.Structure, nil, s.bold)
Group.new('mTagHeaderDirectives', c.softwhite, nil, s.bold)

Group.new('mString', c.green)
Group.new('mDigit', g.Number)
Group.new('mLabelName', c.orange)

-- Group.new('mFunctionCall', c.orange, nil, s.none)
Group.new('mFunctionCall', g.Function.fg:light(.2), nil, s.none)
Group.new('mDoFunctionCall', g.Function)

Group.new('mFunctionParenths', c.softwhite)
Group.new('mFunctionLeftParenth', g.mFunctionParenths)
Group.new('mFunctionRightParenth', g.mFunctionParenths)


