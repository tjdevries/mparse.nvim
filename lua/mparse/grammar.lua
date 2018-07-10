-- TODO:
-- Grammarwise:
--  Indirection, @, @...@
--
-- Programming-wise:
local current_arguments = {}

-- Imports {{{
local token = require('mparse.token')
local patterns = require('mparse.patterns')

local V = patterns.V

-- }}}
-- Option Definitions {{{
local parser_options = {
  parameters_enabled = true,
  strict_compiler_directives = true,
  strict_tag_headers = true,
}
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
local commandOperator = patterns.branch(
  patterns.literal('!'),
  patterns.literal('?'),
  patterns.literal('#')
)

local doCommand = patterns.command_helper("do")
local quitCommand = patterns.command_helper("quit")
local mergeCommand = patterns.command_helper("merge")
local ifCommand = patterns.command_helper("if")
local elseCommand = patterns.command_helper("else")
local xecuteCommand = patterns.command_helper("xecute")
local forCommand = patterns.command_helper("for")
local newCommand = patterns.command_helper("new")
local writeCommand = patterns.branch(
  patterns.command_helper("write")
  , patterns.literal('zw')
)
local setCommand = patterns.command_helper("set")

local normalCommands = patterns.capture(
  patterns.branch(
    mergeCommand,
    elseCommand,
    xecuteCommand,
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

local relationalOperators = patterns.concat(
  patterns.one_or_no(patterns.literal("'")), -- Optional Unary Not
  patterns.branch(
    numericRelationalOperators,
    stringRelationalOperators
  )
)

local logicalOperators = patterns.branch(
  patterns.literal('&'),
  -- patterns.literal('&&'), -- Not ANSI M, so we won't use
  patterns.literal('!'),
  -- patterns.literal('||'), -- Not ANSI M, so we won't use
  patterns.literal("'"),      -- Unary NOT
  patterns.literal("'=")
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
local namedIdentifiers = patterns.branch(
  patterns.concat(
    -- Can optionally start with as '%'
    patterns.one_or_no(patterns.literal('%')),
    -- Must start with a letter
    letter,
    -- Afterwards it can be letters or numbers
    patterns.any_amount(alphanum)
  ),
  -- Or just a '%' all by itself
  patterns.literal('%')
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
  patterns.literal('~'),
  patterns.literal('|')
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

-- }}}
-- {{{ Comment Niceties
-- List of known compiler directives
local verified_compiler_directives = {
  localInline = true,
  endLocalInline = true,
  testTag = true,
  strip = true,
  eor = true,
}

local verified_tag_headers = {
  SCOPE = true,
  DESCRIPTION = true,
  PARAMETERS = true,
  RETURNS = true,
  ['REVISION HISTORY'] = true,
  ['SIDE EFFECTS'] = true,
}
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
      post_conditional_pattern = patterns.zero_match
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
  SUPPRESS(
    "mBody"
    , "mBodyLine"
    , "mArithmeticTokens"
    , "mValidExpression"
    , "mArithmeticExpression"

    , "mCommandFinish"
  )

  -- }}}
  -- Basic Definitions {{{
  -- {{{ mDigit
  mDigit = patterns.capture(patterns.one_or_more(digit))
  -- }}}
  -- Compiler directives are only used within "mComment"
  mCompilerDirective = patterns.capture(
    patterns.concat(
      patterns.literal('#')
      , patterns.function_capture(patterns.any_amount(letter), function(string, index, match)
        if not parser_options.strict_compiler_directives then
          return true
        end

        if verified_compiler_directives[match] then
          return true
        end

        return false
      end)
      , patterns.literal('#')
    )
  )

  mTagHeaderDirectives = patterns.capture(
    patterns.function_capture(
      patterns.concat(
        patterns.any_amount(letter),
        patterns.literal(':')
      ), function(string, index, match)
        if not parser_options.strict_tag_headers then
          return true
        end

        if verified_tag_headers[match:sub(1, -2)] then
          return true
        end

        return false
    end)
  )

  mCommentSemiColon = patterns.capture(patterns.literal(';'))
  mCommentText = patterns.capture(
    patterns.one_or_more(anyCharacter - EOL)
  )

  mComment = patterns.concat( -- {{{
    patterns.capture(
      patterns.concat(
        patterns.one_or_no(start_of_line),
        patterns.any_amount(single_space),
        V("mCommentSemiColon"),
        patterns.one_or_no(V("mCommentSemiColon")),
        patterns.one_or_no(V("mCompilerDirective")),
        patterns.one_or_no(
          patterns.concat(
            patterns.any_amount(single_space),
            V("mTagHeaderDirectives")
          )
        ),
        patterns.one_or_no(V("mCommentText"))
      )
    ),
    patterns.capture(EOL)
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
  mLabel = (
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
      patterns.function_capture(
        patterns.capture(
          patterns.one_or_no(
            patterns.concat(
              V("mFunctionArgument"),
              patterns.any_amount(
                patterns.concat(comma, V("mFunctionArgument"))
              )
            )
          )
        ),
        -- Update the current arguments table
        function (_string, _index, matched)
          if parser_options.parameters_enabled then
            local temp = string.split(matched, ',')

            current_arguments = {}
            for k, v in pairs(temp) do
              current_arguments[v] = true
            end
          end

          return true
        end
      )),
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
      -- TODO: Maybe have a smarter way to check end of line,
      -- since we sometimes consume it in other places
      patterns.one_or_no(EOL)
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
    patterns.one_or_no(
      patterns.branch(
        V("mLogicalOperators")
        , V("mArithmeticOperators")
      )
    ),
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

  mIfOperators = patterns.branch(
    logicalOperators,
    relationalOperators
  )

  mIfInnerExpression = patterns.concat(
    patterns.optional_surrounding_parenths(V("mArithmeticExpression")),
    patterns.any_amount(
      patterns.concat(
        V("mIfOperators"),
        patterns.optional_surrounding_parenths(V("mArithmeticExpression"))
      )
    )
  )

  mIfExpression = patterns.optional_surrounding_parenths(V("mIfInnerExpression"))

  mValidExpression = patterns.branch(
    V("mConditionalExpression"),
    V("mArithmeticExpression")
  )
  -- }}}
  mCommand = patterns.concat( -- {{{
    patterns.branch(
      V("mForCommand"),
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
  -- For Commands {{{
  mForCommand = command_generator({
    name = 'ForCommand',
    starting_pattern = forCommand,
    argument_pattern = patterns.branch(
      patterns.concat(
        single_space,
        V("mSetCommand"),
        single_space,
        patterns.branch(
          patterns.any_amount(
            V("mQuitCommand")
          ),
          V("mDoCommand")
        )
      ),
      -- f idx=<expr>:<expr>:<expr> <command>
      patterns.concat(
        V("mVariable"),
        patterns.literal('='),
        V("mArithmeticTokens"),
        patterns.literal(':'),
        V("mArithmeticTokens"),
        patterns.literal(':'),
        V("mArithmeticTokens"),
        single_space,
        V("mCommand")
      )
    ),

    disable_optional_argument_parenths = true,

    -- TODO: I suppose it's possible, but I've never seen it.
    accepts_post_conditional = false,
  })
  -- }}}
  -- Do Commands {{{
  mDoCommand = command_generator({
    name = 'DoCommand',
    starting_pattern = doCommand,
    argument_pattern = V("mDoCommandArgs"),
    whitespace_pattern = patterns.zero_match,

    disable_optional_argument_parenths = true,
  })

  mDoCommandArgs = patterns.branch(
    patterns.concat(
      single_space,
      V("mDoFunctionCall")
    ),
    patterns.concat(
      patterns.branch(
        -- d
        -- . <commands>
        EOL,
        -- d  w "something"
        -- . w "first"
        patterns.concat(
          single_space,
          single_space,
          V("mCommand"),
          EOL
        )
      )
      , patterns.one_or_more(
          patterns.concat(
            -- TODO: Control dot levels here
            patterns.any_amount(whitespace)
            , #patterns.literal('.')
            , #patterns.any_amount(patterns.literal(' .'))
            , V("mBodyLine")
          )
        )
      -- , V("mBodyLine")
    )
  )

  -- }}}
  -- If Commands {{{
  -- TODO: Else, else if
  mIfCommand = command_generator({
    name = 'IfCommand',
    starting_pattern = ifCommand,

    argument_pattern = patterns.concat(
      patterns.optional_surrounding_parenths(
        V("mIfCommandArgs")
      ),
      single_space,
      V("mCommand")
    ),

    accepts_post_conditional = false,
    disable_optional_argument_parenths = true,
  })

  _mIfCommandSection = patterns.branch(
    V("mIfExpression"),
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
  mWriteCommandArgs = patterns.one_or_more(
    patterns.branch(
      V("mCommandOperator"),
      V("mCommandSeparator"),
      V("mValidExpression")
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
    whitespace_pattern = patterns.zero_match or 1,

    accepts_post_conditional = true,
  })

  -- Any arithmetic expression should work I think
  -- TODO: Might want to have a better name for this, like string concatenation, etc.
  mQuitCommandArgs = patterns.branch(
    #EOL,
    patterns.concat(
      single_space,
      single_space,
      V("mDoCommand")
    ),
    patterns.concat(
      single_space,
      V("mValidExpression")
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
      )
    )
  )
  -- }}}
  -- All Commands {{{
  mCommandSeparator = patterns.capture(comma)
  mCommandOperator = patterns.capture(
    patterns.concat(
      commandOperator,
      patterns.one_or_no(V("mDigit"))
    )
  )
  mCommandArgs = patterns.any_amount(
    patterns.branch(
      V("mCommandSeparator"),
      V("mFunctionCall"),
      V("mCommandOperator"),
      -- TODO: Some of these digits are not getting captured correctly
      V("mDigit"),
      V("mString"),
      V("mVariable"),
      anyCharacter
    )
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
        patterns.look_ahead(EOL),
        E('Unexpected Arguments to command. No previous handling')
      )
    )
  )
  -- }}}
  -- mVariables {{{
  -- Checks what the current parameters are,
  -- and then if it matches, then we say it's a parameter
  -- Should allow for highlight parameters with different colors!
  mParameter = patterns.capture(
    patterns.function_capture(
      V("mVariableNonArray"),
      function (_string, _index, matched)
        if not parser_options.parameters_enabled then
          return false
        end

        if type(matched) ~= 'table' then
          return false
        end

        if matched.value == nil then
          return false
        end

        if current_arguments[matched.value] then
          -- print('================================================================================')
          -- local inspect = require('mparse.inspect')
          -- print(inspect(current_arguments))
          return true
        else
          return false
        end
      end
    )
  )

  mIndirectionOperator = patterns.capture(patterns.literal('@'))
  mVariableIntrinsic = patterns.capture(
    patterns.concat(
      patterns.literal('$'),
      variableIdentifiers
    )
  )
  mVariableGlobal = patterns.capture(
    patterns.concat(
      patterns.literal('^'),
      namedIdentifiers,
      patterns.one_or_no(
        patterns.concat(
          left_parenth,
          V("mValidExpression"),
          patterns.any_amount(
            patterns.concat(
              comma,
              V("mValidExpression")
            )
          ),
          right_parenth
        )
      )
    )
  )
  mVariableNonArray = patterns.capture(variableIdentifiers)
  mVariableArray = patterns.capture(
    patterns.concat(
      patterns.branch(
        -- HANDLE: @<expression>@(...)
        patterns.concat(
          V("mIndirectionOperator"),
          -- TODO: Somehow get more inclusive options here
          patterns.subset_expression(
            patterns.branch(
              V("mString")
              , V("mVariableNonArray")
              , V("mFunctionCall")
            )
            , patterns.branch(
              V("mOperator")
              , V("mLogicalOperators")
            )
          ),
          V("mIndirectionOperator")
        ),
        -- HANDLE: <variableName>(...)
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
        V("mIndirectionOperator"),
        patterns.optional_surrounding_parenths(V("mValidExpression"))
      )
    ),
    -- Should not end with an '@'. That's an array indirection
    patterns.neg_look_ahead(V("mIndirectionOperator")),
    patterns.look_ahead(
      patterns.branch(
        V("mCommandSeparator"),
        EOL,
        patterns.end_of_file
      )
    )
  )
  mVariable = patterns.capture(
    patterns.branch(
      V("mParameter")
      , V("mVariableIntrinsic")
      , V("mVariableGlobal")
      , V("mVariableArray")
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
  mFunctionLeftParenth = patterns.capture(left_parenth)
  mFunctionRightParenth = patterns.capture(right_parenth)

  mDoFunctionCall = patterns.concat(
    patterns.capture(calledFunctionIdentifiers),
    V("mFunctionLeftParenth"),
    patterns.any_amount(
      patterns.branch(
        V("mValidExpression"),
        comma
      )
    ),
    V("mFunctionRightParenth")
  )
  -- }}}
  -- Errors {{{
  mError = (1 - EOL) ^ 1
  mCapturedError = patterns.capture(V("mError"))
  -- }}}
end)

local get_current_arguments = function() return current_arguments end

return { -- {{{
  m_grammar = m_grammar,
  options = parser_options,

  -- Debug functions, useful for testing the current state
  __get_current_arguments = get_current_arguments,
} -- }}}
