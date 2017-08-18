""
" Find where labels are in this file
function! mparse#find_labels() abort
  " return luaeval('require("mparse.init").find_labels()')

  let old_pos = getcurpos()
  normal! gg

  let search_options = 'cW'
  let label_lines = []

  while search('^\%[%]\S*(.*)', search_options)
      call add(label_lines, line('.'))

      let search_options = 'W'
  endwhile

  call setpos('.', old_pos)

  return label_lines
endfunction
