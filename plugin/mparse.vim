" this is all there is
" another line

function! MHighlight() abort
    return luaeval('require("mparse.init").highlight()')
endfunction

" TODO:
" mFunctionArgument

" TODO: Get this programatically from the highlighting plugin
" it should sent out metadata
CPHL mCommand Statement - -
for command_type in ['Do', 'Write', 'New', 'Normal', 'Set', 'Quit', 'If']
    call execute(printf('CPHL m%sCommand mCommand - -', command_type))
endfor

CPHL mCommandOperator yellow - -

" We don't actually highlight mvariable directly usually,
" but we can highlight nonarrays and arrays differently!
CPHL mVariable blue - -
CPHL mVariableNonArray mVariable - -
CPHL mVariableArray blue,dark - -

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
