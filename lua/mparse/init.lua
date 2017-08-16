-- TODO:
--   - Incremental parsing
--   - More highlighting items (perhaps automated)
--   - Better highlighting colors
local highlighter = require('mparse.highlighter')

local plugin = {}

plugin.highlight = function()
  return highlighter.apply_highlights(0)
end

return plugin
