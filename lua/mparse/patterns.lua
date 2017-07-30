-- local lpeg = require('lpeg')
local lpeg = require('lulpeg.lulpeg')

local P, R, S, B, C, Cc, Ct, Cp, Cg, V =
  lpeg.P, lpeg.R, lpeg.S, lpeg.B, lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cp, lpeg.Cg, lpeg.V

local fold = function (func, ...)
  local result = nil
  for i, v in ipairs({...}) do
    if result == nil then
      result = v
    else
      result = func(result, v)
    end
  end
  return result
end

local folder = function (func)
  return function (...)
    return fold(func, ...)
  end
end

local patterns = {}

-- Determines if the start, finish are closed
-- and creates a group capture of "name"
patterns.closed = function(start, finish, name)
  return P({
    start * Cg(((1 - S(start .. finish)) + V(1))^0, name) * finish
  })
end

patterns.listOf = function(patt, sep)
  patt, sep = P(patt), P(sep)

  return patt * (sep * patt)^0
end

patterns.g_paren = patterns.closed('(', ')', '_')

patterns.split = function(value, sep)
  local g_split = P({
    Ct(V("elem") * (V("sep") * V("elem"))^0),

    sep = S(sep .. "()"),
    elem = C(((1-V("sep")) + g_paren)^0),
  })

  return lpeg.match(g_split, value)
end

patterns.literal = lpeg.P
patterns.set = function(...)
  return lpeg.S(fold(function (a, b) return a .. b end, ...))
end
patterns.any_character = lpeg.P(1)
patterns.range = function(s, e) return lpeg.R(s .. e) end
patterns.concat = folder(function (a, b) return a * b end)
patterns.branch = folder(function (a, b) return a + b end)
patterns.one_or_more = function(v) return v ^ 1 end
patterns.two_or_more = function(v) return v ^ 2 end
patterns.any_amount = function(v) return v ^ 0 end
patterns.one_or_no = function(v) return v ^ -1 end
patterns.look_behind = lpeg.B
patterns.look_ahead = function(v) return #v end
patterns.neg_look_ahead = function(v) return -v end
patterns.neg_look_behind = function(v) return -patterns.look_behind(v) end
patterns.optional_surrounding = function(start, finish, v)
  return patterns.branch(
    patterns.concat(
      start,
      v,
      finish
    ),
    v
  )
end

-- command_helper("do") -> "do", "DO", "Do", "d", "D",
patterns.command_helper = function(s)
  return patterns.branch(
    patterns.literal(s),
    patterns.literal(s:upper()),
    patterns.literal(s:sub(1,1):upper() .. s:sub(2)),
    patterns.literal(s:sub(1,1)),
    patterns.literal(s:sub(1,1):upper())
  )
end


function string:split(sep)
  local sep, fields = sep or ",", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields + 1] = c end)
  return fields
end

return patterns
