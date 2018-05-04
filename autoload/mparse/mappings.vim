""
" Handle enter in insert mode
" Sends a comment character (";")for applicable lines
function! mparse#mappings#insert_enter() abort
  let current_line = getline('.')

  let dot_level = py3eval(printf('("""%s""").count("""%s""")', current_line, ". "))

  " Blank lines or lines with spaces
  if match(current_line, '^\s*$') >= 0
    return ";\<CR>"
  endif

  if match(current_line, '^\s*;$') >= 0
    return "\<CR>;"
  endif

  " Blank dotted lines
  if match(current_line, '^\s*\(\. \)*\%[\.]$') >= 0
    return ";\<CR>"
  endi

  " Send the global mapping of <CR> in insert mode
  " echo char2nr(std#mapping#execute_global('i', "\<CR>"))
  return std#mapping#execute_global('i', "<CR>")
endfunction
