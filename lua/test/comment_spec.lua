local epnf = require('mparse.token')

local grammar = require('mparse.grammar')
local m = grammar.m_grammar

local helpers = require('test.helpers')
local eq = helpers.eq
local neq = helpers.neq

-- TODO: Shift to m.mComment to parse these
describe('comment', function()
  it('should accept easy strings', function()
    local parsed = epnf.parsestring(m.mComment, [[; this is a comment]])
    neq(nil, parsed)
    eq('mComment', parsed.id)
    eq('; this is a comment', parsed.value)
  end)

  it('should be fine with special characters', function()
    local parsed = epnf.parsestring(m.mComment, [[; "this" ! is all comment __]])
    neq(nil, parsed)
    eq('mComment', parsed.id)
    eq('; "this" ! is all comment __', parsed.value)
  end)

  it('should not include the extra items', function()
    local parsed = epnf.parsestring(m.mComment, [[; this is a comment
myNotComment() q
]])

    neq(nil, parsed)
    eq('mComment', parsed.id)
    eq('; this is a comment', parsed.value)
  end)

  it('should handle all sorts of stuff', function()
    local parsed = epnf.parsestring(m, [[
 ; s threshold=$$GetEncDupThreshold^LDEDUPENC(0)
 ; s IPonly=$s(option=7:1,option=9:1,1:"") ;for option 7 and 9, we only want hospital admissions
 ; s EDonly=$s(option=8:1,1:"") ;for option 8, we only want ED visits
 ; s includeAry("loadProviderDetails")=1
 ; s dischThreshMax=10,dischThreshCount=0
 ; d:(latestInst="")!(latestInst]"") helloWorld()
 ; w !,eptID,2*55
 ; W !,helloWorld
 ; i $$IsCollectingMetadata() s hbNodes(0)=0,includeAry("originalData")=1
 ; d %zgtStartEndTime(startDate,lookback,.latestInst,.earliestInst,spfRule)
 ; i (latestInst=""),(earliestInst="") q ""
 ; i ((option=7)!(option=9)) s encContext("searchParameters","range","overlapping")=1
]])
    neq(nil, parsed)
    neq(nil, helpers.get_item(parsed, 'id', 'mComment'))
  end)

  it('should handle comments at the end of the line and the next line', function()
    local parsed = epnf.parsestring(m, [[
myLabel() ; comment
  w !,"hello"  ; comment
  ; another comment
]])
    neq(nil, parsed)
  end)

end)
