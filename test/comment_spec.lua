local lpeg = require('lpeg')

local epnfs = require('src.token')

local grammar = require('src.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq = helpers.eq

describe('comment', function()
  it('should accept easy strings', function()
    eq('mComment', helpers.get_first_item(epnfs.parsestring(m, [[
; this is a comment
; this is another
]])).id)
  end)

  it('should accept multiple comments', function()
    local parsed = epnf.parsestring(m, [[
; comment 1
; comment 2
;
; empty comment before
]])
  end)
end)
