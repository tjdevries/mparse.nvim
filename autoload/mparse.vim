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

let s:source_file = expand('<sfile>')

""
" Reload all of our lua files, so that we don't have to restart nvim
function! mparse#_force_reload() abort
  " Make sure to have all reasonable slashes
  let lua_dir = substitute(fnamemodify(s:source_file, ':h:h') . '/lua/mparse/', '\\', '/', 'g')

  " Make sure that we have reasonable slashes in the whole thing
  let raw_lua_files = map(glob(lua_dir . '*.lua', v:false, v:true), { idx, val -> substitute(val, '\\', '/', 'g') })

  let lua_files = map(
        \ raw_lua_files,
        \ { idx, val -> substitute(substitute(val, lua_dir, 'mparse.', ' '), '.lua', '', '') }
        \ )

  for l_file in lua_files
    call execute('lua package.loaded["' . l_file . '"] = nil')
  endfor
endfunction
