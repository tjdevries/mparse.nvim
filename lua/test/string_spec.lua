local lpeg = require('lpeg')

local epnfs = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq = helpers.eq

describe('string', function()
  it('should accept easy strings', function()
    eq('mString', epnfs.parsestring(m.mString, [["this is a string"]]).id)
  end)

  it('should accept special characters', function()
    eq('mString', epnfs.parsestring(m.mString, [["this is a stright with ! # and others."]]).id)
  end)

  it('should accept single quotes', function()
    eq('mString', epnfs.parsestring(m.mString, [["this is a stright with ' in it."]]).id)
  end)

  it('should accept _ characters', function()
    eq(
      'mString',
      epnfs.parsestring(m.mString, [["this a string with _ in it!."]]).id
    )
  end)
end)
