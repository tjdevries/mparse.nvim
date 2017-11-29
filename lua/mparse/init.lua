local highlighter = require('mparse.highlighter')
local incremental = require('mparse.incremental')

local plugin = {}

plugin.highlight = function()
  return highlighter.apply_highlights(0)
end

plugin.find_labels = function()
  return incremental.find_labels()
end

return plugin
