-- TODO:
--  Indirection, @, @...@

local lpeg = require('lpeg')
local re = require('re')

local epnfs = require('mparse.token')
local helper = require('mparse.helper')
local patterns = require('mparse.patterns')
local util = require('mparse.util')


local P, R, S, B, C, Cc, Ct, Cp, Cg, Cb, V =
  lpeg.P, lpeg.R, lpeg.S, lpeg.B, lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cp, lpeg.Cg, lpeg.Cb, lpeg.V

-- Standard definitions {{{
local whitespace = patterns.set(
  ' ',
  '\t',
  '\v',
  '\n',
  '\f'
)
local optionalWhitespace = patterns.one_or_no(whitespace)

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

local normalCommands = C(patterns.branch(
  quitCommand,
  mergeCommand,
  ifCommand,
  elseCommand,
  xecuteCommand,
  forCommand,
  P"g",
  P"goto",
  P"c",
  P"close",
  P"h",
  P"halt",
  P"hang",
  P"k",
  P"kill",
  P"l",
  P"lock",
  P"r",
  P"read",
  P"tc",
  P"tcommit",
  P"tre",
  P"trestart",
  P"tro",
  P"trollback",
  P"ts",
  P"tstart",
  P"u",
  P"use"))
-- }}}
-- Function type items {{{
local check_declaration_parameters = function(...)
  local args = {...}

  if args == {} then
    return nil
  end

  if args.value then
    if epnfs.declaration_parameters() == nil then
      return nil
    end

    if epnfs.declaration_parameters()[args.value] then
      return args
    end
  end

  return nil
end
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
local nonQuoteAscii = S'.'
  + S'!'
  + S','
  + S'#'
  + S'$'
  + S'%'
  + S'('
  + S')'
  + S'*'
  + S'='
  + S'_'
  + S'\''

local stringCharacter = patterns.branch(
  alphanum,
  whitespace,
  nonQuoteAscii
)

local anyCharacter = stringCharacter +  S'"'
-- }}}
-- {{{ Line and File Identifiers
-- Optional end of line matching
local EOL = P"\r"^-1 * P"\n"

local startOfLine = patterns.branch(
  patterns.look_behind(patterns.literal('\n')),
  patterns.look_behind(patterns.literal(''))
)

-- }}}
-- ordered choice of all tokens and last-resort error which consumes one character
local m_grammar = epnfs.define( function(_ENV)

  START "mFile"

  mFile = V("mBlock") * (EOL^-1) + Ct("")
  mBlock = Ct(
    V("mComment")
    + V("mLabel")
    + V("mCommand")
    + V("mString")
    + whitespace
    + EOL
    + 1
  )^0

  mComment = patterns.concat(
    #optionalWhitespace,
    C(P';' * helper.untilChars('\n'))
  )

  mString = C(patterns.concat(
    patterns.literal('"'),
    stringCharacter^0,
    patterns.literal('"')
  ))

  mLabel = patterns.concat(
    startOfLine,
    V("mLabelName"),
    -- patterns.one_or_no(V("mArgumentDeclaration")),
    V("mArgumentDeclaration"),
    V("mBody")
  )

  mLabelName = C(namedIdentifiers)

  mArgument = patterns.one_or_more(alphanum)

  -- I'm splitting this in `make_ast_node`, I'd like to not do that
  mArgumentDeclaration = patterns.closed('(', ')', 'closed_paren')
    * patterns.listOf(Cb('closed_paren'), ',')

  -- Group for body
  mBody = (V("mComment") + V("mBodyLine"))^0

  -- TODO: Make a dotted line
  mBodyLine = optionalWhitespace * V("mCommand") * EOL

  -- M Arithmetic Expressions {{{
  mArithmeticOperators = C(arithmeticOperators)

  mArithmeticExpression = patterns.one_or_more(
    patterns.branch(
      V("mDigit"),
      V("mString"),
      V("mArithmeticOperators"),
      V("mVariable"),
      V("mFunctionCall")
    )
  )
  -- }}}


  mCommand = patterns.branch(
    V("mDoCommand"),
    V("mWriteCommand"),
    V("mNewCommand"),
    V("mSetCommand"),
    V("mNormalCommand")
  )

  -- Do Commands {{{
  mDoCommand = patterns.concat(
    C(doCommand),
    patterns.one_or_no(V("mPostConditional")),
    whitespace,
    V("mDoCommandArgs")
  )

  mDoCommandArgs = V("mDoFunctionCall")
  mDoFunctionCall = patterns.concat(
    C(calledFunctionIdentifiers),
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
  -- Set Commands {{{
  mSetCommand = patterns.concat(
    C(setCommand),
    patterns.one_or_no(V("mPostConditional")),
    whitespace,
    V("mSetCommandArgs")
  )

  mSetCommandArgs = patterns.branch(
    patterns.concat(
      patterns.one_or_more(
        patterns.branch(
          V("mCommandSeparator"),
          V("mSetExpression")
        )
      ),
      patterns.look_ahead(whitespace)
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
    C(writeCommand),
    patterns.one_or_no(V("mPostConditional")),
    whitespace,
    V("mCommandArgs")
  )
  -- }}}
  -- New Commands {{{
  mNewCommand = patterns.concat(
    C(newCommand),
    patterns.one_or_no(V("mPostConditional")),
    whitespace,
    V("mNewCommandArgs")
  )

  mNewCommandArgs = patterns.concat(
    patterns.one_or_more(
      patterns.branch(
        V("mVariable"),
        V("mCommandSeparator")
      )
    ),
    V("mCapturedError"),
    EOL
  )

  -- }}}
  -- {{{ Normal Command
  mNormalCommand = patterns.concat(
    C(normalCommands),
    patterns.one_or_no(V("mPostConditional")),
    whitespace,
    patterns.one_or_no(V("mCommandArgs"))
  )
  -- }}}
  -- Post Conditionals {{{
  mPostConditionalSeparator = C(patterns.literal(':'))
  -- TODO: Add =,+, etc.
  mPostConditionalExpression = patterns.concat(
    patterns.one_or_no(left_parenth),
    patterns.branch(
      V("mFunctionCall"),
      patterns.literal('='),
      V("mVariable")
    ),
    patterns.one_or_no(right_parenth)
  )

  -- TODO: Match the parenths
  mPostConditional = patterns.concat(
    V("mPostConditionalSeparator"),
    C(
      patterns.concat(
        patterns.one_or_more(V("mPostConditionalExpression")),
        #whitespace
      )
    )
  )
  -- }}}
  -- All Commands {{{
  mCommandSeparator = C(comma)
  mCommandOperator = V("mDigit") * C(commandOperator)
  -- }}}

  mCommandArgs = (
    V("mCommandSeparator")
      + V("mFunctionCall")
      + V("mCommandOperator")
      -- TODO: Some of these digits are not getting captured correctly
      + V("mDigit")
      + V("mString")
      -- TODO: Add this with back captures or something.
      -- Not sure how to get it to work correctly
      -- + V("mParameter")
      + V("mVariable")
      + anyCharacter
    - EOL)


  -- Checks what the current parameters are,
  -- and then if it matches, then we say it's a parameter
  -- Should allow for highlight parameters with different colors!
  mParameter = Cb('closed_paren') * P(namedIdentifiers)

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

  mVariable = C(
    patterns.branch(
      V("mVariableNonArray"),
      V("mVariableArray")
    )
  )

  mFunctionCall = C(
    patterns.concat(
      patterns.branch(
        (P'$$' + P'$')
      ),
      V("mDoFunctionCall")
    )
  )

  -- Extra
  mDigit = C(digit^1)

  mError = (1 - EOL) ^ 1
  mCapturedError = C(patterns.one_or_no(V("mError")))
end)

return {
  m_grammar=m_grammar,

  -- If parameter finding enabled
  parameters_enabled=false,
}
