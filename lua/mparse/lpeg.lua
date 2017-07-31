-- If the user has "lpeg", then use it ,
-- otherwise, use the included lulpeg.
--
-- lulpeg is slower than lpeg, so that's why we prefer lpeg
--
-- luacheck: globals _ENV
local success, lpeg = pcall(require, 'lpeg')
return (success and lpeg) or require('lulpeg.lulpeg'):register(not _ENV and _G)
