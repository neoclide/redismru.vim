# 🚩 Redismru.vim

Most recently used files plugin for vim using Redis and job-control feature.

It's build for speed! Since every IO operation is async, **it won't block the UI
as other MRU plugins did**!

It works for vim with `has('job')` (there's bug for vim on the callback support,
so it's note working) and neovim.

##🔍Install

* install redis with command like:

        brew install redis

* install node with command like:

        brew install node

_node script is used for async file validte_

* install this plugin and unite.vim with plugin manager like vim-plug by:

        Plug 'Shougo/unite.vim'
        Plug 'chemzqm/redismru.vim'

* CD to the project root and run:

        npm install

##♨ Usage

* Open unite source with redismru source like:

        Unite redismru

* Validate the all mru files manully:

        :MruValidate

_validate would start async when vim start, so you normally don't need this_

see `h:redismru` to learn more.

## License

MIT
