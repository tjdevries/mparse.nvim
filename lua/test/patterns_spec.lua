local patterns = require('mparse.patterns')

local helpers = require('test.helpers')
local eq, neq = helpers.eq, helpers.neq

describe('patterns', function()
  it('should match all the expected capitalizations', function()
    local pattern = patterns.command_helper('do')

    eq(nil, pattern:match('hello'))
    neq(nil, pattern:match('DO'))

    -- print(require('mparse.util').to_string(patterns.capture(pattern:match('do'))))
    -- print(require('mparse.util').to_string(patterns.capture(pattern:match('d'))))
    -- print(pattern:match('D'))
    -- print(pattern:match('d'))
  end)
end)
