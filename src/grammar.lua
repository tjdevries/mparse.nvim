local lpeg = require 'lpeg'
local re = require 're'

local epnfs = require 'src.token'
local helper = require 'src.helper'
local patterns = require 'src.patterns'
local util = require 'src.util'


local P, R, S, B, C, Cc, Ct, Cp, Cg, Cb, V =
  lpeg.P, lpeg.R, lpeg.S, lpeg.B, lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cp, lpeg.Cg, lpeg.Cb, lpeg.V

local whitespace = S' \t\v\n\f'^1

local comma = S','
local digit = R'09'
local letter = R('az', 'AZ') + P'_'
local alphanum = letter + digit

-- standard commands {{{
local command = C(
  P"d" +
  P"do" +
  P"g" +
  P"goto" +
  P"c" +
  P"close" +
  P"e" +
  P"else" +
  P"f" +
  P"for" +
  P"h" +
  P"halt" +
  P"hang" +
  P"i" +
  P"if" +
  P"k" +
  P"kill" +
  P"l" +
  P"lock" +
  P"m" +
  P"merge" +
  P"n" +
  P"new" +
  P"q" +
  P"quit" +
  P"r" +
  P"read" +
  P"s" +
  P"set" +
  P"tc" +
  P"tcommit" +
  P"tre" +
  P"trestart" +
  P"tro" +
  P"trollback" +
  P"ts" +
  P"tstart" +
  P"u" +
  P"use" +
  P"w" +
  P"write" +
  P"x" +
  P"xecute") * #whitespace
-- }}}

-- Function type items

local commandOperator = S'!'

local mValidIdentifiers = R('AZ', 'az', '09')
local nonQuoteAscii = S'.'
  + S'!'
  + S','
  + S'#'
  + S'$'
  + S'%'
  + S'('
  + S')'
  + S'*'
local mValidString = mValidIdentifiers
  + whitespace
  + nonQuoteAscii

local mAny = mValidString +  S'"'

-- Optional end of line matching
local EOL = P"\r"^-1 * P"\n"

-- ordered choice of all tokens and last-resort error which consumes one character
local m_grammar = epnfs.define( function(_ENV)

  START "mFile"

  mFile = V("mBlock") * (EOL^-1) + Ct("")
  mBlock = Ct(
    V("mComment")
    + V("mLabel")
    + V("mCommand")
    + V("mString")
    + V("mWhitespace")
    + EOL
    + 1
  )^0

  mComment = C(P';' * helper.untilChars('\n'))

  -- lpeg.match(lpeg.S('"') * lpeg.C(lpeg.R("az")^0) * lpeg.S('"'), '"hi"')
  mString = S'"' * C(mValidString^0) * S'"'

  mLabel = V("mLabelName")
    * V("mArgumentDeclaration")
    * V("mBody")

  mLabelName = C((P'%' + R'AZ') * R('AZ', 'az', '09')^0)

  mArgument = R('AZ', 'az', '09')^1
  -- I'm splitting this in `make_ast_node`, I'd like to not do that
  mArgumentDeclaration = patterns.closed('(', ')', 'closed_paren')
    * patterns.listOf(Cb('closed_paren'), ',')

  -- Group for body
  mBody = (V("mComment") + V("mBodyLine") + V("mWhitespace"))^0

  -- TODO: Make a dotted line
  mBodyLine = V("mWhitespace")^0
    * V("mCommand")
    * EOL


  mWhitespace = whitespace
  mCommand = V("mWhitespace") * command * V("mWhitespace") * V("mCommandArgs")^0

  mCommandSep = comma
  mCommandOperation = commandOperator
  mCommandOperator = V("mDigit") * V("mCommandOperation")

  mCommandArgs = (
    (V("mCommandSep")
      + V("mCommandOperator")
      + V("mString")
      + V("mParameter")
      + V("mVariable")
      + mAny)
    - EOL)

  -- Checks what the current parameters are,
  -- and then if it matches, then we say it's a parameter
  -- Should allow for highlight parameters with different colors!
  mParameter = lpeg.Cf(C(V("mVariable")), function(s, i , a, b)
    if epnfs.declaration_parameters() == nil then
      return nil
    end

    if a == nil then
      return nil
    end

    if a.value == nil then
      return nil
    end

    return epnfs.declaration_parameters()[a.value]
  end)
  mVariable = C((mValidIdentifiers + digit + S'^' + S'%')^1)

  -- Extra
  mDigit = digit

  mError = P(1)
end )

return {
  m_grammar=m_grammar
}
