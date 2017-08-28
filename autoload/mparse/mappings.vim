""
" Handle enter in insert mode
" Sends a comment character (";")for applicable lines
function! mparse#mappings#insert_enter() abort
  " Blank lines or lines with spaces
  if match(getline('.'), '^\s*$') >= 0
    return ";\<CR>"
  endif

  " Blank dotted lines
  if match(getline('.'), '^\s*\(\. \)*\%[\.]$') >= 0
    return ";\<CR>"
  endi

  " Send the global mapping of <CR> in insert mode
  return std#mapping#execute_global('i', '<CR>')
endfunction
