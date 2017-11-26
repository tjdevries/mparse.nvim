" this is all there is
" another line

function! MHighlight() abort
    return luaeval('require("mparse.init").highlight()')
endfunction

" TODO:
" mFunctionArgument

if !exists(':CPHL')
    finish
endif

" TODO: Get this programatically from the highlighting plugin
" it should sent out metadata
CPHL mCommand Statement - -
for command_type in ['Do', 'Write', 'New', 'Normal', 'Set', 'Quit', 'If']
    call execute(printf('CPHL m%sCommand mCommand - -', command_type))
endfor

CPHL mCommandOperator yellow - -
CPHL mSetCommandOperator mCommandOperator mCommandOperator mCommandOperator

" We don't actually highlight mvariable directly usually,
" but we can highlight nonarrays and arrays differently!
CPHL mVariable blue - -
CPHL mVariableNonArray blue0 - -
CPHL mVariableIndirect blue0 - -
CPHL mVariableArray blue1 - -

CPHL mParameter blue2 - bold

CPHL mComment Comment - Comment
CPHL mCompilerDirective purple - bold

CPHL mString green - -
CPHL mDigit blue0 - -
CPHL mLabelName orange1 - -

CPHL mFunctionCall yellow - -
CPHL mDoFunctionCall orange - -

" CPHL mError Error - -
CPHL mCapturedError white red underline
" CPHL mBuiltinFunctionCall

" Operators
CPHL mPostConditionalSeparator red0 - -
