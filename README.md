# mparse.nvim

lpeg based parser -> highlighter for m in nvim

Includes a (slower) version of LPEG in this repository. Install `$ luarocks install lpeg` to use that.

### TODO:

- Allow searching of values within different syntax items
  - Search for the word "med" only inside of comments
- Allow additional parsing rules
  - For example, parsing headers
