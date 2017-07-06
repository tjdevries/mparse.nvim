local lpeg = require 'lpeg'

local P, R, S, B, C, Cc, Ct, Cp, Cg, V =
  lpeg.P, lpeg.R, lpeg.S, lpeg.B, lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cp, lpeg.Cg, lpeg.V


-- Determines if the start, finish are closed
-- and creates a group capture of "name"
local closed = function(start, finish, name)
  return P({
    start * Cg(((1 - S(start .. finish)) + V(1))^0, name) * finish
  })
end

local listOf = function(patt, sep)
  patt, sep = P(patt), P(sep)

  return patt * (sep * patt)^0
end

local g_paren = closed('(', ')', '_')

local split = function(value, sep)
  local g_split = P({
    Ct(V("elem") * (V("sep") * V("elem"))^0),

    sep = S(sep .. "()"),
    elem = C(((1-V("sep")) + g_paren)^0),
  })

  return lpeg.match(g_split, value)
end

function string:split(sep)
  local sep, fields = sep or ",", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields + 1] = c end)
  return fields
end

return {
  closed=closed,
  listOf=listOf,
  split=split,
}
