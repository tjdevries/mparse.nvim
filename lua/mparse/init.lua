local highlighter = require('mparse.highlighter')

local plugin = {}

plugin.highlight = function()
  highlighter.apply_highlights(0)
end


return plugin
