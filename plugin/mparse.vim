" this is all there is
" another line

function! MHighlight() abort
    return luaeval('require("mparse.init").highlight()')
endfunction

" TODO:
" mFunctionArgument

CPHL mCommand Statement - -
CPHL mDoCommand mCommand - -
CPHL mWriteCommand mCommand - -
CPHL mNewCommand mCommand - -
CPHL mNormalCommand mCommand - -
CPHL mSetCommand mCommand - -
CPHL mQuitCommand mCommand - -

CPHL mCommandOperator yellow - -

CPHL mVariable blue - -
CPHL mParameter blue - bold
CPHL mComment Comment - Comment
CPHL mString String - -
CPHL mDigit Number - -
CPHL mLabelName purple - -

CPHL mPrefixFuncionCall blue - -

CPHL mFunctionCall orange - -
CPHL mDoFunctionCall mFunctionCall,dark - -

" CPHL mError Error - -
CPHL mCapturedError white red underline
" CPHL mBuiltinFunctionCall

" Operators
CPHL mPostConditionalSeparator Operator - -
