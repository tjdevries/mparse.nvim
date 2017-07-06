local m_grammar = require('mparse.grammar').m_grammar

-- public interface  {{{
-- Get the items
local filename = arg[1]
local fh = assert(io.open(filename))
local input = fh:read'*a'
fh:close()

-- Print the items
print(input, '-->')
print(util.to_string(m_grammar:match(input)))
-- }}}

