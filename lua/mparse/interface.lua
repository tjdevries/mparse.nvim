local epnf = require('mparse.token')
local m_grammar = require('mparse.grammar').m_grammar
local util = require('mparse.util')

-- public interface  {{{
-- Get the items
local filename = arg[1]
local fh = assert(io.open(filename))
local input = fh:read'*a'
fh:close()

-- Print the items
print(input, '-->')
print(util.to_string(epnf.parsestring(m_grammar, input)))
-- }}}

