local lpeg = require('lpeg')

local epnfs = require('src.token')

local grammar = require('src.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq = helpers.eq

describe('string', function()
  it('should accept easy strings', function()
    eq('mString', helpers.get_first_item(epnfs.parsestring(m, [[
"this is a string"
]]
      )).id
    )
  end)

  it('should accept special characters', function()
    eq('mString', helpers.get_first_item(epnfs.parsestring(m, [[
"this is a stright with ! # and others."
]]
      )).id
    )
  end)
end)
