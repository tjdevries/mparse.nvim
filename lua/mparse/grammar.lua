-- TODO:
-- Grammarwise:
--  Indirection, @, @...@
--
-- Programming-wise:
--  Use lpeg whenever available, otherwise lulpeg.

-- Imports {{{
local token = require('mparse.token')
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

local anyOperator = patterns.branch(
  relationalOperators,
  logicalOperators,
  concatenationOperators,
  setCommandOperators,
  arithmeticOperators
)
-- }}}
-- Name Identifiers {{{
local namedIdentifiers = patterns.concat(
  -- Can optionally start with as '%'
  patterns.one_or_no(patterns.literal('%')),
  -- Must start with a letter
  letter,
  -- Afterwards it can be letters or numbers
  patterns.any_amount(alphanum)
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
  patterns.literal('@'),
  patterns.literal('!'),
  patterns.literal('?'),
  patterns.literal('#'),
  patterns.literal('$'),
  patterns.literal('%'),
  patterns.literal('&'),
  patterns.literal('('),
  patterns.literal(')'),
  patterns.literal('*'),
  patterns.literal('+'),
  patterns.literal(','),
  patterns.literal('-'),
  patterns.literal('.'),
  patterns.literal('/'),
  patterns.literal(':'),
  patterns.literal(';'),
  patterns.literal('<'),
  patterns.literal('='),
  patterns.literal('>'),
  patterns.literal('['),
  patterns.literal('\''),
  patterns.literal(']'),
  patterns.literal('^'),
  patterns.literal('_'),
  patterns.literal('`'),
  patterns.literal('{'),
  patterns.literal('}'),
  patterns.literal('~')
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

-- local start_of_line = patterns.capture(
local start_of_line = patterns.concat(
  patterns.start_of_line,
  patterns.any_amount(single_space),
  patterns.any_amount(
    patterns.concat(
      patterns.literal('.'),
      single_space
    )
  )
)

local captured_single_space = patterns.capture(single_space)
-- }}}
-- luacheck: no unused args
local m_grammar = token.define(function(_ENV)
  -- Helper functions for the grammar {{{
  local error_capture = function(msg)
    return patterns.branch(E(msg), V("mCapturedError"))
  end

  local ternary = function(condition, if_true, if_false)
    if condition then
      return if_true
    else
      return if_false
    end
  end

  local command_generator = function(options)
    if options.name == nil then
      error('options needs "name"')
    end
    local name = options.name
    local error_message = options.error_message

    if options.starting_pattern == nil then
      error('options needs "starting_pattern"')
    end
    local starting_pattern = options.starting_pattern

    if options.argument_pattern == nil then
      error('options needs "argument_pattern"')
    end
    local argument_pattern = options.argument_pattern


    -- Determine whether to use post conditional
    local accepts_post_conditional = true
    if options.accepts_post_conditional ~= nil then
      accepts_post_conditional = options.accepts_post_conditional
    end

    local post_conditional_pattern = patterns.one_or_no(V("mPostConditional"))
    if not accepts_post_conditional then
      post_conditional_pattern = patterns.look_ahead(patterns.any_character)
    end

    local whitespace_pattern = single_space
    if options.whitespace_pattern ~= nil then
      whitespace_pattern = options.whitespace_pattern
    end

    -- Get the command args set up
    local disable_optional_argument_parenths = options.disable_optional_argument_parenths or false
    local complete_argument_pattern = ternary(
      disable_optional_argument_parenths,
      patterns.branch(
        argument_pattern,
        patterns.concat(
          patterns.optional_surrounding_parenths(argument_pattern),
          E(string.format("Surrounding parenths not allowed in: '%s'", name))
        )
      ),
      patterns.optional_surrounding_parenths(argument_pattern)
    )

    return patterns.concat(
      patterns.capture(starting_pattern),
      post_conditional_pattern,
      whitespace_pattern,
      patterns.branch(
        complete_argument_pattern,
        error_capture(error_message or string.format("Error while parsing: '%s'", name))
      )
    )
  end
  -- }}}
  -- START is an operative made from token {{{
  -- luacheck: globals START
  START "mFile"
  -- luacheck: globals SUPPRESS
  SUPPRESS "mParameterFinder"
  -- }}}
  -- Basic Definitions {{{
  -- {{{ mDigit
  mDigit = patterns.capture(patterns.one_or_more(digit))
  -- }}}
  mComment = patterns.concat( -- {{{
    patterns.capture(
      -- TODO: Don't highlight dots like comments
      patterns.concat(
        patterns.branch(
          patterns.one_or_no(start_of_line),
          patterns.any_amount(captured_single_space)
        ),
        patterns.literal(';'),
        -- Anything up to end of line
        patterns.any_amount(anyCharacter - EOL)
      )
    ),
    EOL
  ) -- }}}
  mString = patterns.capture(patterns.concat( -- {{{
    patterns.literal('"'),
    patterns.any_amount(stringCharacter),
    patterns.literal('"')
  ))
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
  mLabel = patterns.capture(
    patterns.concat(
      patterns.start_of_line,
      V("mLabelName"),
      patterns.one_or_no(V("mArgumentDeclaration")),
      single_space,
      V("mBody")
    )
  )
  -- }}}
  -- mArgument* {{{
  mFunctionArgument = patterns.capture(patterns.one_or_more(alphanum))

  mArgumentDeclaration = patterns.concat(
    left_parenth,
    patterns.capture(
      patterns.group_capture(
        patterns.one_or_no(
          patterns.concat(
            V("mFunctionArgument"),
            patterns.any_amount(
              patterns.concat(comma, V("mFunctionArgument"))
            )
          )
        )
      ),
      -- Name of the group
      "functionArguments"
    ),
    right_parenth,
    #whitespace
  )
  -- }}}
  -- mBody* {{{
  -- Group for body
  mBody = patterns.concat(
    patterns.one_or_more(
      patterns.branch(
        V("mComment"),
        V("mBodyLine")
      )
    ),
    -- The body ends when a file ends
    -- Or we see a new label coming up
    patterns.branch(
      #patterns.end_of_file,
      #V("mLabel")
    )
  )

  -- TODO: I want body line to never fail and to send an error when it encounters unparseable items
  mBodyLine = patterns.concat(
    start_of_line,
    -- patterns.branch(
    --   patterns.one_or_more(V("mCommand"))
    --   error_capture("Broken body line") * EOL
    -- ),
    patterns.one_or_more(V("mCommand")),
    patterns.branch(
      V("mComment"),
      EOL
    )
  )
  -- }}}
  -- M Expressions {{{
  mArithmeticOperators = patterns.capture(arithmeticOperators)
  mConcatenationOperators = patterns.capture(concatenationOperators)
  mRelationalOperators = patterns.capture(relationalOperators)
  mLogicalOperators = patterns.capture(logicalOperators)
  mOperator = patterns.capture(anyOperator)

  mArithmeticTokens = patterns.optional_surrounding_parenths(
    patterns.branch(
      V("mString"),
      V("mFunctionCall"),
      V("mVariableByReference"),
      V("mVariable"),
      V("mDigit")
    )
  )

  mArithmeticExpression = patterns.concat(
    V("mArithmeticTokens"),
    patterns.any_amount(
      patterns.branch(
        V("mOperator"),
        V("mArithmeticTokens")
      )
    )
  )

  mConditionalExpression = patterns.concat(
    V("mArithmeticExpression"),
    V("mPostConditionalSeparator"),
    V("mArithmeticExpression")
  )

  mValidExpression = patterns.branch(
    V("mConditionalExpression"),
    V("mArithmeticExpression")
  )
  -- }}}
  mCommand = patterns.concat( -- {{{
    patterns.branch(
      V("mDoCommand"),
      V("mWriteCommand"),
      V("mNewCommand"),
      V("mSetCommand"),
      V("mQuitCommand"),
      V("mIfCommand"),
      V("mNormalCommand")
    ),
    V("mCommandFinish")
  ) -- }}}
  -- Do Commands {{{
  mDoCommand = command_generator({
    name = 'DoCommand',
    starting_pattern = doCommand,
    argument_pattern = V("mDoCommandArgs"),

    disable_optional_argument_parenths = true,
  })

  mDoCommandArgs = V("mDoFunctionCall")
  -- }}}
  -- If Commands {{{
  -- TODO: Else, else if
  mIfCommand = command_generator({
    name = 'IfCommand',
    starting_pattern = ifCommand,

    argument_pattern = patterns.concat(
      patterns.optional_surrounding(
        left_parenth,
        right_parenth,
        V("mIfCommandArgs")
      ),
      single_space,
      V("mCommand")
    ),

    accepts_post_conditional = false,
    disable_optional_argument_parenths = true,
  })

  _mIfCommandSection = patterns.branch(
    V("mConditionalExpression"),
    V("mValidExpression")
  )

  mIfCommandArgs = patterns.concat(
    V("_mIfCommandSection"),
    patterns.any_amount(
      patterns.concat(
        V("mCommandSeparator"),
        V("_mIfCommandSection")
      )
    )
  )

  -- }}}
  -- Set Commands {{{
  mSetCommand = command_generator({
    name = 'SetCommand',
    starting_pattern = setCommand,
    argument_pattern = V("mSetCommandArgs"),
  })

  mSetCommandArgs = patterns.one_or_more(
    patterns.branch(
      V("mCommandSeparator"),
      V("mSetExpression")
    )
  )

  -- variable=generalExpression
  mSetOperator = patterns.capture(setCommandOperators)
  mSetExpression = patterns.concat(
    V("mVariable"),
    V("mSetOperator"),
    V("mValidExpression")
  )
  -- }}}
  -- Write Commands {{{
  mWriteCommand = command_generator({
    name = 'WriteCommand',
    starting_pattern = writeCommand,
    argument_pattern = V("mWriteCommandArgs"),
  })

  -- TODO: Make sure to make the order of these correct and that they are as independent as possible
  mWriteCommandArgs = patterns.concat(
    V("mValidExpression"),
    patterns.any_amount(
      patterns.branch(
        V("mCommandOperator"),
        V("mCommandSeparator"),
        V("mValidExpression")
      )
    )
  )
  -- }}}
  -- New Commands {{{
  mNewCommand = command_generator({
    name = 'NewCommand',
    starting_pattern = newCommand,
    argument_pattern = V("mNewCommandArgs"),
  })

  mNewCommandArgs = patterns.concat(
    V("mVariable"),
    patterns.any_amount(
      patterns.concat(
        -- TODO: This should not actually be mVariable, since it will capture arrays,
        --  which shouldn't be allowed to be newed
        V("mCommandSeparator"),
        patterns.branch(
          V("mVariable"),
          error_capture("Not a valid item to set in SetCommand")
        )
      )
    )
  )

  -- }}}
  -- Quit Commands {{{
  mQuitCommand = command_generator({
    name = 'QuitCommand',
    starting_pattern = quitCommand,
    argument_pattern = V("mQuitCommandArgs"),
    whitespace_pattern = patterns.one_or_no(single_space),
  })

  -- Any arithmetic expression should work I think
  -- TODO: Might want to have a better name for this, like string concatenation, etc.
  mQuitCommandArgs = patterns.concat(
    patterns.branch(
      patterns.end_of_line,
      patterns.concat(
        patterns.look_behind(single_space),
        V("mValidExpression")
      )
    )
  )
  -- }}}
  -- {{{ Normal Command
  mNormalCommand = command_generator({
    name = 'Generic Command',
    starting_pattern = normalCommands,
    argument_pattern = V("mCommandArgs")
  })
  -- }}}
  -- Post Conditionals {{{
  mPostConditionalSeparator = patterns.capture(patterns.literal(':'))
  mPostConditionalExpression = patterns.optional_surrounding_parenths(V("mValidExpression"))

  -- TODO: Match the parenths
  mPostConditional = patterns.concat(
    V("mPostConditionalSeparator"),
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
  mCommandFinish = patterns.branch(
    patterns.look_ahead(
      patterns.branch(
        single_space,
        EOL
      )
    ),
    -- Still not sure if this captures all the items I'm looking for
    patterns.one_or_no(
      patterns.concat(
        patterns.look_ahead(patterns.end_of_line),
        E('Unexpected Arguments to command. No previous handling')
      )
    )
  )
  -- }}}
  -- mVariables {{{
  -- Checks what the current parameters are,
  -- and then if it matches, then we say it's a parameter
  -- Should allow for highlight parameters with different colors!
  -- mParameter = Cb('closed_paren') * namedIdentifiers
  -- mParameter = patterns.back_capture('functionArguments')
  mParameter = patterns.function_capture(V("mVariableNonArray"), function (string, index, left, right)
    print('================================================================================')
    print('s:', string)
    print('i:', index)
    print('@:', string[index])
    print('l:', require('mparse.util').to_string(left))
    print('r:', right)

    if pcall(patterns.back_capture('functionArguments')) then
      print('B:', patterns.back_capture('functionArguments'))
    else
      print('B:', 'Nope')
    end
    print('================================================================================')
    return false
  end)

  mVariableNonArray = patterns.capture(variableIdentifiers)
  mVariableArray = patterns.capture(
    patterns.concat(
      patterns.branch(
        patterns.concat(
          patterns.literal('@'),
          V("mValidExpression"),
          patterns.literal('@')
        ),
        namedIdentifiers
      ),
      left_parenth,
      patterns.one_or_more(
        patterns.branch(
          comma,
          V("mValidExpression")
        )
      ),
      right_parenth
    )
  )
  mVariableIndirect = patterns.concat(
    patterns.capture(
      patterns.concat(
        patterns.literal('@'),
        patterns.optional_surrounding_parenths(V("mValidExpression"))
      )
    ),
    -- Should not end with an '@'. That's an array indirection
    patterns.neg_look_ahead(patterns.literal('@')),
    patterns.look_ahead(
      patterns.branch(
        V("mCommandSeparator"),
        patterns.end_of_line,
        patterns.end_of_file
      )
    )
  )
  mVariable = patterns.capture(
    patterns.branch(
      -- V("mParameter") ,
      V("mVariableArray")
      , V("mVariableNonArray")
      , V("mVariableIndirect")
    )
  )

  mVariableByReference = patterns.capture(
    patterns.literal('.'),
    V("mVariableNonArray")
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
        V("mValidExpression"),
        comma
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
