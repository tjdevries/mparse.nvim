-- TODO:
-- Grammarwise:
--  Indirection, @, @...@
--
-- Programming-wise:
--  Use lpeg whenever available, otherwise lulpeg.

-- Imports {{{
local epnfs = require('mparse.token')
local patterns = require('mparse.patterns')

local V = patterns.V

-- }}}
-- Standard definitions {{{
local single_space = patterns.literal(' ')
local whitespace = patterns.set(
  ' ',
  '\t',
  '\v',
  '\f'
)

local left_parenth = patterns.literal('(')
local right_parenth = patterns.literal(')')
local comma = patterns.literal(',')
local digit = patterns.range('0', '9')
local letter = patterns.branch(
  patterns.range('a', 'z'),
  patterns.range('A', 'Z')
)
local alphanum = patterns.branch(letter, digit)
-- }}}
-- standard commands {{{
local commandOperator = patterns.literal('!')

local doCommand = patterns.command_helper("do")
local quitCommand = patterns.command_helper("quit")
local mergeCommand = patterns.command_helper("merge")
local ifCommand = patterns.command_helper("if")
local elseCommand = patterns.command_helper("else")
local xecuteCommand = patterns.command_helper("xecute")
local forCommand = patterns.command_helper("for")
local newCommand = patterns.command_helper("new")
local writeCommand = patterns.command_helper("write")
local setCommand = patterns.command_helper("set")

local normalCommands = patterns.capture(
  patterns.branch(
    mergeCommand,
    ifCommand,
    elseCommand,
    xecuteCommand,
    forCommand,
    patterns.literal("g"),
    patterns.literal("goto"),
    patterns.literal("c"),
    patterns.literal("close"),
    patterns.literal("h"),
    patterns.literal("halt"),
    patterns.literal("hang"),
    patterns.literal("k"),
    patterns.literal("kill"),
    patterns.literal("l"),
    patterns.literal("lock"),
    patterns.literal("r"),
    patterns.literal("read"),
    patterns.literal("tc"),
    patterns.literal("tcommit"),
    patterns.literal("tre"),
    patterns.literal("trestart"),
    patterns.literal("tro"),
    patterns.literal("trollback"),
    patterns.literal("ts"),
    patterns.literal("tstart"),
    patterns.literal("u"),
    patterns.literal("use")
  )
)
-- }}}
-- {{{ Arithmetic / Expression patterns
local numericRelationalOperators = patterns.branch(
  patterns.literal('<'),   -- Less than
  patterns.literal('>'),   -- Greater than
  patterns.literal('\'<'), -- NOT less than
  patterns.literal('\'>')  -- NOT greater than
)

local stringRelationalOperators = patterns.branch(
  patterns.literal('='),  -- Binary equals
  patterns.literal('['),  -- Binary contains. Whether the first operand contains the second
  patterns.literal(']'),  -- Binary follows, converts both operands to strings. First operand follows second.
  patterns.literal(']]'), -- Binary sorts after, first operand comes after the second in numeric subscript
  patterns.literal('?')   -- Pattern matching
)

local relationalOperators = patterns.branch(
  numericRelationalOperators,
  stringRelationalOperators
)

local logicalOperators = patterns.branch(
  patterns.literal('&'),
  -- patterns.literal('&&'), -- Not ANSI M, so we won't use
  patterns.literal('!'),
  -- patterns.literal('||'), -- Not ANSI M, so we won't use
  patterns.literal("'")      -- Unary NOT
)

local concatenationOperators = patterns.literal('_')

local setCommandOperators = patterns.literal('=')

local arithmeticOperators = patterns.branch(
  patterns.literal('+'),
  patterns.literal('-'),
  patterns.literal('*'),
  patterns.literal('/'),  -- Divide
  patterns.literal('\\'), -- Integer division
  patterns.literal('#')   -- Modulo division
)
-- }}}
-- Name Identifiers {{{
local namedIdentifiers = patterns.concat(
  patterns.one_or_no(patterns.literal('%')),
  patterns.one_or_more(alphanum)
)

-- Variables can't have "(" at the end of their name
local variableIdentifiers = patterns.concat(
  namedIdentifiers,
  patterns.neg_look_ahead(left_parenth)
)

-- myTag^myRoutine(...)
local tagSeparator = patterns.literal('^')
local calledFunctionIdentifiers = patterns.concat(
  namedIdentifiers,
  patterns.one_or_no(
    patterns.concat(
      tagSeparator,
      namedIdentifiers
    )
  ),
  patterns.look_ahead(left_parenth)
)
-- }}}
-- {{{ String Identifiers
local nonQuoteAscii = patterns.branch(
  patterns.literal('.'),
  patterns.literal('!'),
  patterns.literal(','),
  patterns.literal('#'),
  patterns.literal('$'),
  patterns.literal('%'),
  patterns.literal('('),
  patterns.literal(')'),
  patterns.literal('*'),
  patterns.literal('='),
  patterns.literal('_'),
  patterns.literal('\'')
)

local stringCharacter = patterns.branch(
  alphanum,
  whitespace,
  nonQuoteAscii
)

local anyCharacter = stringCharacter +  patterns.literal('"')
-- }}}
-- {{{ Line and File Identifiers
-- Optional end of line matching or end of string (which is kind of like end of line :) )
local EOL = patterns.branch(
  patterns.end_of_line,
  patterns.end_of_file
)

local startOfLine = patterns.branch(
  patterns.look_behind(patterns.literal('\n')),
  patterns.look_behind(patterns.literal(''))
)

-- }}}
-- M grammar, non-recursive and testable items

-- ordered choice of all tokens and last-resort error which consumes one character
-- luacheck: no unused args
local m_grammar = epnfs.define( function(_ENV)

  -- START is an operative made from epnfs
  -- luacheck: globals START
  START "mFile"

  -- Basic Definitions {{{
  -- {{{ mDigit
  mDigit = patterns.capture(patterns.one_or_more(digit))
  -- }}}
  mComment = patterns.concat( -- {{{
    patterns.capture(
      patterns.concat(
        patterns.literal(';'),
        patterns.any_amount(anyCharacter)
      )
    ),
    EOL
  ) -- }}}
  mString = patterns.capture(patterns.concat( -- {{{
    patterns.literal('"'),
    patterns.any_amount(stringCharacter),
    patterns.literal('"')
  ))

  mConcatenationOperators = patterns.capture(concatenationOperators)
  -- }}}
  -- }}}
  -- {{{ mFile
  mFile = patterns.concat(
    V("mBlock"),
    patterns.end_of_file
  )
  -- }}}
  --  {{{ mBlock
  mBlock = patterns.any_amount(
    patterns.branch(
      V("mComment"),
      V("mLabel")
    )
  ) -- }}}
  -- mLabel* {{{
  mLabelName = patterns.capture(namedIdentifiers)
  mLabel = patterns.concat(
    startOfLine,
    V("mLabelName"),
    patterns.one_or_no(V("mArgumentDeclaration")),
    single_space,
    V("mBody")
  )
  -- }}}
  -- mArgument* {{{
  mFunctionArgument = patterns.capture(patterns.one_or_more(alphanum))

  mArgumentDeclaration = patterns.concat(
    left_parenth,
    patterns.capture(patterns.one_or_no(
      patterns.concat(
        V("mFunctionArgument"),
        patterns.any_amount(
          patterns.concat(comma, V("mFunctionArgument"))
        )
      )
    )),
    right_parenth,
    #whitespace
  )
  -- }}}
  -- mBody* {{{
  -- Group for body
  mBody = patterns.one_or_more(
    patterns.branch(
      V("mBodyLine"),
      V("mComment")
    )
  )

  -- TODO: Make a dotted line
  mBodyLine = patterns.concat(
    patterns.any_amount(whitespace),
    patterns.one_or_more(V("mCommand")),
    patterns.one_or_no(V("mComment")),
    EOL
  )
  -- }}}
  -- M Expressions {{{
  mArithmeticOperators = patterns.capture(arithmeticOperators)

  mArithmeticExpression = patterns.one_or_more(
    patterns.branch(
      V("mDigit"),
      V("mString"),
      V("mArithmeticOperators"),
      V("mVariable"),
      V("mFunctionCall")
    )
  )

  mStringExpression = patterns.concat(
    V("mString"),
    patterns.one_or_more(
      patterns.concat(
        V("mConcatenationOperators"),
        V("mString")
      )
    )
  )

  mInnerRelationalExpression = patterns.concat(
    V("mArithmeticExpression"),
    relationalOperators,
    V("mArithmeticExpression")
  )
  mRelationalExpression = patterns.optional_surrounding(
    left_parenth, right_parenth, V("mInnerRelationalExpression")
  )
  -- }}}
  mCommand = patterns.concat( -- {{{
    patterns.branch(
      V("mDoCommand"),
      V("mWriteCommand"),
      V("mNewCommand"),
      V("mSetCommand"),
      V("mQuitCommand"),
      V("mNormalCommand")
    ),
    V("mCommandFinish")
  ) -- }}}
  -- Do Commands {{{
  mDoCommand = patterns.concat(
    patterns.capture(doCommand),
    patterns.one_or_no(V("mPostConditional")),
    whitespace,
    V("mDoCommandArgs")
  )

  mDoCommandArgs = V("mDoFunctionCall")
  -- }}}
  -- Set Commands {{{
  mSetCommand = patterns.concat(
    patterns.capture(setCommand),
    patterns.one_or_no(V("mPostConditional")),
    whitespace,
    V("mSetCommandArgs")
  )

  mSetCommandArgs = patterns.branch(
    patterns.one_or_more(
      patterns.branch(
        V("mCommandSeparator"),
        V("mSetExpression")
      )
    ),
    patterns.one_or_no(V("mCapturedError"))
  )

  -- variable=generalExpression
  mSetExpression = patterns.concat(
    V("mVariable"),
    setCommandOperators,
    V("mArithmeticExpression")
  )
  -- }}}
  -- Write Commands {{{
  mWriteCommand = patterns.concat(
    patterns.capture(writeCommand),
    patterns.one_or_no(V("mPostConditional")),
    single_space,
    V("mWriteCommandArgs")
  )

  _mWriteCommandSection = patterns.branch(
    V("mCommandOperator"),
    V("mDigit"),
    V("mString"),
    V("mVariable"),
    V("mRelationalExpression"),
    V("mArithmeticExpression"),
    V("mFunctionCall")
  )
  mWriteCommandArgs = patterns.branch(
    patterns.concat(
      V("_mWriteCommandSection"),
      patterns.any_amount(
        patterns.concat(
          patterns.branch(
            V("mConcatenationOperators"),
            V("mCommandSeparator")
          ),
          V("_mWriteCommandSection")
        )
      )
    ),
    V("mCapturedError")
  )
  -- }}}
  -- New Commands {{{
  mNewCommand = patterns.concat(
    patterns.capture(newCommand),
    patterns.one_or_no(V("mPostConditional")),
    single_space,
    V("mNewCommandArgs")
  )

  mNewCommandArgs = patterns.concat(
    patterns.concat(
      V("mVariable"),
      patterns.branch(
        patterns.any_amount(
          patterns.concat(
            -- TODO: This should not actually be mVariable, since it will capture arrays,
            --  which shouldn't be allowed to be newed
            V("mCommandSeparator"),
            V("mVariable")
          )
        )
        -- E("borken new")
      )
    )
    -- TODO: Get mCapturedError to work well
    -- E("broken variable")
  )

  -- }}}
  -- Quit Commands {{{
  mQuitCommand = patterns.concat(
    patterns.capture(quitCommand),
    patterns.one_or_no(V("mPostConditional")),
    patterns.branch(
      patterns.one_or_no(
        patterns.concat(
          single_space,
          V("mQuitCommandArgs")
        )
      ),
      V("mCapturedError")
    )
  )

  -- Any arithmetic expression should work I think
  -- TODO: Might want to have a better name for this, like string concatenation, etc.
  mQuitCommandArgs = patterns.capture(
    patterns.branch(
      V("mArithmeticExpression"),
      V("mString")
    )
  )
  -- }}}
  -- {{{ Normal Command
  mNormalCommand = patterns.concat(
    patterns.capture(normalCommands),
    patterns.one_or_no(V("mPostConditional")),
    whitespace,
    patterns.one_or_no(V("mCommandArgs"))
  )
  -- }}}
  -- Post Conditionals {{{
  mPostConditionalSeparator = patterns.capture(patterns.literal(':'))
  mPostConditionalExpression = V("mRelationalExpression")

  -- TODO: Match the parenths
  mPostConditional = patterns.concat(
    V("mPostConditionalSeparator"),
    patterns.capture(
      patterns.concat(
        V("mPostConditionalExpression"),
        patterns.any_amount(
          patterns.concat(
            patterns.branch(logicalOperators, comma),
            V("mPostConditionalExpression")
          )
        ),
        #whitespace
      )
    )
  )
  -- }}}
  -- All Commands {{{
  mCommandSeparator = patterns.capture(comma)
  mCommandOperator = patterns.capture(
    patterns.concat(
      patterns.one_or_no(V("mDigit")),
      commandOperator
    )
  )
  mCommandArgs = patterns.branch(
    V("mCommandSeparator"),
    V("mFunctionCall"),
    V("mCommandOperator"),
    -- TODO: Some of these digits are not getting captured correctly
    V("mDigit"),
    V("mString"),
    -- TODO: Add this with back captures or something.
    -- Not sure how to get it to work correctly
    -- + V("mParameter")
    V("mVariable"),
    anyCharacter
  )
  mCommandFinish = patterns.look_ahead(
    patterns.branch(
      whitespace,
      EOL
    )
  )
  -- }}}
  -- mVariables {{{
  -- Checks what the current parameters are,
  -- and then if it matches, then we say it's a parameter
  -- Should allow for highlight parameters with different colors!
  -- mParameter = Cb('closed_paren') * namedIdentifiers

  mVariableNonArray = variableIdentifiers
  mVariableArray = patterns.concat(
    namedIdentifiers,
    left_parenth,
    patterns.one_or_more(
      patterns.branch(
        comma,
        V("mDigit"),
        V("mVariableArray"),
        V("mVariableNonArray"),
        V("mString")
      )
    ),
    right_parenth
  )

  mVariable = patterns.capture(
    patterns.branch(
      V("mVariableNonArray"),
      V("mVariableArray")
    )
  )
  -- }}}
  -- mFunctions {{{
  mFunctionCall = patterns.capture(
    patterns.concat(
      patterns.branch(
        patterns.literal('$$'),
        patterns.literal('$')
      ),
      V("mDoFunctionCall")
    )
  )
  mDoFunctionCall = patterns.concat(
    patterns.capture(calledFunctionIdentifiers),
    left_parenth,
    patterns.any_amount(
      patterns.branch(
        comma,
        V("mArithmeticExpression")
      )
    ),
    right_parenth
  )

  -- }}}
  -- Errors {{{
  mError = (1 - EOL) ^ 1
  mCapturedError = patterns.capture(patterns.one_or_no(V("mError")))
  -- }}}
end)

return { -- {{{
  m_grammar=m_grammar,

  -- If parameter finding enabled
  parameters_enabled=false,
} -- }}}
