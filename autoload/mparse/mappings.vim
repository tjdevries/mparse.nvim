let s:mparse_mapping_debug = v:true

let s:InsertEnter = {}

function! s:InsertEnter.new() dict
  let insert_enter = {}
  let insert_enter.found = v:false
  let insert_enter.prefix = ''
  let insert_enter.postfix = ''
  let insert_enter.mark_found = s:InsertEnter.mark_found
  let insert_enter.mapping = s:InsertEnter.mapping

  return insert_enter
endfunction

function! s:InsertEnter.mark_found(prefix, postfix) dict
  let self.found = v:true
  let self.prefix = a:prefix
  let self.postfix = a:postfix
endfunction

function! s:InsertEnter.mapping(dot_level) dict
  return self.prefix . repeat('. ', a:dot_level) . self.postfix
endfunction


""
" Handle enter in insert mode
" Sends a comment character (";")for applicable lines
function! mparse#mappings#insert_enter() abort
  let current_line = getline('.')

  let dot_split = split(matchstr(current_line, '^\s*\(\. \)*\%[\.]'), '\. ', 1)
  let dot_level = len(dot_split) - 1

  let insert_enter = s:InsertEnter.new()

  " Blank lines
  if match(current_line, '^\s*$') >= 0
    if s:mparse_mapping_debug
      echo 'Blank line...'
    endif

    call insert_enter.mark_found(";\<CR>", '')

  " Lines with spaces
  elseif match(current_line, '^\s*;$') >= 0
    if s:mparse_mapping_debug
      echo 'Comment line...?'
    endif

    call insert_enter.mark_found("\<CR>;", '')

  " Blank dotted lines
  elseif match(current_line, '^\s*\(\. \)*\%[\.]$') >= 0
    if s:mparse_mapping_debug
      echo 'Blank dotted line...'
    endif

    call insert_enter.mark_found(";\<CR>", '')

  " Dotted lines with a comment
  elseif match(current_line, '^\s*\(\. \)*\%[\.];') >= 0
    if s:mparse_mapping_debug
      echo 'Blank dotted line...'
    endif

    call insert_enter.mark_found("\<CR>", ';')

  " Dotted line of code
  elseif match(current_line, '^\s*\(\. \)*\%[\.]') >= 0
    if s:mparse_mapping_debug
      echo 'Something on a dotted line...'
    endif

    call insert_enter.mark_found("\<CR>", '')
  endif

  if insert_enter.found
    return insert_enter.mapping(dot_level)
  endif

  " Send the global mapping of <CR> in insert mode
  " echo char2nr(std#mapping#execute_global('i', "\<CR>"))
  return std#mapping#execute_global('i', "<CR>")
endfunction
