local epnf = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('mCommands', function()
  describe('mNewCommand', function()
    it('should not detect other commands', function()
      eq(nil, epnf.parsestring(m.mNewCommand, 'q hello'))
    end)
  end)
end)
