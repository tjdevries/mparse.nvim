" this is all there is
" another line

try
    execute('luafile ' . expand('<sfile>:h') . '/highlighter.lua')
catch
endtry

function! MHighlight() abort
    call luaeval('require("mparse.init")')
endfunction

CPHL mCommand Statement - -
CPHL mCommandOperator yellow - -
CPHL mVariable blue - -
CPHL mParameter blue - bold
CPHL mComment Comment - Comment
CPHL mString String - -
CPHL mDigit Number - -
CPHL mLabelName Function - -

CPHL mPrefixFuncionCall blue - -
CPHL mFunctionCall yellow - -
" CPHL mBuiltinFunctionCall

