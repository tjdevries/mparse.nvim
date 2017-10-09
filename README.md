# mparse.nvim

lpeg based parser -> highlighter for m in nvim

Includes a (slower) version of LPEG in this repository. 

I would recommend installing `lpeg` and using that. Install `$ luarocks install lpeg` to use that.

## Install

I would recommend installing lpeg, as it's faster than the shipped pure lua lpeg I have here.

```vim

call plug#begin()

Plug 'tweekmonster/colorpal.vim'
Plug 'tjdevries/mparse.nvim'

call plug#end()
```

### TODO:

- Allow searching of values within different syntax items
  - Search for the word "med" only inside of comments
- Allow additional parsing rules
  - For example, parsing headers

## Thanks

Thanks to github.com/siffiejoe/lua-luaepnf. That's where the majority of the `lua/mparse/token.lua` code comes from.

Thanks to github.com/pygy/lulpeg. That's where all of the bundled `./lua/lulpeg` code comes from.
