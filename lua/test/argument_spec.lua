local token = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('mLabel:', function()
  describe('[argument finding]', function()
    it('should find arguments', function()
      local parsed = token.parsestring(m, [[
testLabel(arg1,arg2) q arg1
]])
      local label = helpers.get_item(parsed, 'id', 'mLabel')

      -- eq({}, label)
    end)
  end)
end)
