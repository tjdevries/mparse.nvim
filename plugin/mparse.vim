" this is all there is
" another line

function! MHighlight() abort
    return luaeval('require("mparse.init").highlight()')
endfunction

if exists(':CPHL')
    call mparse#colorpal#setup()
endif

" TODO: Check if we have colorbuddy.vim
if v:true
    call execute('luafile ' . expand('<sfile>:h') . '/mparse_colors.lua')
endif
