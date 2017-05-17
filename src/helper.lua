local lpeg = require 'lpeg'

local P, R, S, B, C, Cc, Ct, Cp, Cg, V =
  lpeg.P, lpeg.R, lpeg.S, lpeg.B, lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cp, lpeg.Cg, lpeg.V

-- Capture until these chars
local function untilChars(chars) return ((1 - P(chars))^0 * #P(chars)) end

-- Captures items inside the chars
local function insideChars(chars) return S(chars) * untilToken(chars) end

-- Captures items within the chars
local function withinChars(start, patt, finish)
  return B(start) * patt * S(finish)
end


return {
  untilChars=untilChars,
  insideChars=insideChars,
  withinChars=withinChars,
}
