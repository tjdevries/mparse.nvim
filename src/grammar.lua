local lpeg = require 'lpeg'
local re = require 're'

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

-- local floatnum = digit^1 * exp * fs^-1 +
--                  digit^0 * P'.' * digit^1 * exp^-1 * fs^-1 +
--                  digit^1 * P'.' * digit^0 * exp^-1 * fs^-1

-- create a pattern which captures the lua value [id] and the input matching
-- [patt] in a table
local function token(id, patt)
  -- print(id, patt, type(patt))
  -- return Ct(Cc(id) * C(patt))
  return Ct(Cc(id) * C(patt) * Cp(patt))
end


-- standard commands {{{
local mCommand = C(
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
local mValidString = mValidIdentifiers + whitespace
local mAny = mValidString + S'!' + S',' + S'"'

-- Optional end of line matching
local EOL = S'\n'^-1

-- ordered choice of all tokens and last-resort error which consumes one character
m_grammar = P{
  "mFile";

  mFile = V("mBlock") * EOL + Ct(""),
  mBlock = Ct(
    V("mComment")
    + V("mLabel")
    + V("mCommand")
    + V("mString")
    + V("mWhitespace")
  ),

  mComment = P';' * helper.untilChars('\n')
    / util.mark('mComment'),


  -- lpeg.match(lpeg.S('"') * lpeg.C(lpeg.R("az")^0) * lpeg.S('"'), '"hi"')
  mString = (S'"' * C(mValidString^0) * S'"')
    / util.mark('mString'),

  mLabel = V("mLabelName")
    * V("mArgumentDeclaration")
    * V("mBody")
    / util.mark('mLabel'),

  mLabelName = (P'%' + R'AZ') * R('AZ', 'az', '09')^0
    / util.mark('mLabelName'),

  mArgument = R('AZ', 'az', '09')^1 /
    util.mark('mArgument'),
  mArgumentDeclaration = patterns.closed('(', ')', 'closed_paren')
    * (Cb('closed_paren'))
    / util.mark('mLabelParens'),

  -- Group for body
  mBody = (V("mComment") + V("mBodyLine") + V("mWhitespace"))^0,

  -- TODO: Make a dotted line
  mBodyLine = V("mWhitespace")^0
    * V("mCommand") * EOL,


  mWhitespace = whitespace
    / util.mark('mWhitespace'),
  mCommand = mCommand * V("mWhitespace") * V("mCommandArgs")^0
    / util.mark('mCommand'),

  mCommandSep = comma,
  mCommandOperation = commandOperator
    / util.mark('mCommandOperation'),
  mCommandOperator = V("mDigit") * V("mCommandOperation")
    / util.mark('mCommandOperator'),

  mCommandArgs = V("mCommandSep") + V("mCommandOperator") + V("mString") + mAny
    / util.mark('mCommandArgs'),

  -- Extra
  mDigit = digit
    / util.mark('digit'),

  mError = P(1) / util.mark('Error'),
} * -1

-- public interface  {{{
-- Get the items
local filename = arg[1]
local fh = assert(io.open(filename))
local input = fh:read'*a'
fh:close()

-- Print the items
print(input, '-->')
print(util.to_string(m_grammar:match(input)))
-- }}}
