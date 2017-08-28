
" We use custom syntax highlighting. No need to even run the syntax command
syntax clear
setlocal commentstring=;%s

" TODO: Allow the user to configure how often they want highlighting to run

autocmd BufEnter,BufReadPost,BufWritePost <buffer> call MHighlight()

" TODO: Call this to only incrementally highlight.
" Don't highlight anything before this line.
" Try not to highlight anything AFTER this label as well
autocmd CursorHold <buffer> silent! call MHighlight()

inoremap <buffer><expr> <CR> mparse#mappings#insert_enter()
