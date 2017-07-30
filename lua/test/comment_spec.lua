local lpeg = require('lpeg')

local epnfs = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq = helpers.eq
local neq = helpers.neq

-- TODO: Shift to m.mComment to parse these
describe('comment', function()
  it('should accept easy strings', function()
    local parsed = epnfs.parsestring(m.mComment, [[; this is a comment]])
    neq(nil, parsed)
    eq('mComment', parsed.id)
    eq('; this is a comment', parsed.value)
  end)

  it('should be fine with special characters', function()
    local parsed = epnfs.parsestring(m.mComment, [[; "this" ! is all comment __]])
    neq(nil, parsed)
    eq('mComment', parsed.id)
    eq('; "this" ! is all comment __', parsed.value)
  end)

  it('should not include the extra items', function()
    local parsed = epnfs.parsestring(m.mComment, [[; this is a comment
myNotComment() q
]])

    neq(nil, parsed)
    eq('mComment', parsed.id)
    eq('; this is a comment', parsed.value)
  end)
end)
