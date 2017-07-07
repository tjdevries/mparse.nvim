local lpeg = require('lpeg')

local epnfs = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq = helpers.eq

-- TODO: Shift to m.mComment to parse these
describe('comment', function()
  it('should accept easy strings', function()
    eq('mComment', helpers.get_first_item(epnfs.parsestring(m, [[
; this is a comment
; this is another
]])).id)
  end)

  it('should accept multiple comments', function()
    local parsed = epnfs.parsestring(m, [[
; comment 1
; comment 2
;
; empty comment before
]])
  end)
end)
