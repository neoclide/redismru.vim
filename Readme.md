# 🚩 Redismru.vim

Most recently used files plugin for vim using Redis and job-control feature.

Some MRU would cost nearly 50ms to load MRU files at vim startup, this plugin
use async job-control feature to avoid it.

It works for neovim and vim with `has('job')` (there's bug for vim on the callback support,
so it's not working).

Redismru also perform MRU list load on CursorHold, this makes work with multiply
vim instances easier.

![redismru](https://chemzqm.me/images/02-23/redismru.jpg)

**Note**, async file load at startup and would cost 10~100ms, you
can't get the list before it finish.

##🔍Install

* install redis with command like:

        brew install redis

* install node with command like:

        brew install node

_node script is used for async file validate (started on vim leave)_

* install this plugin and unite.vim with plugin manager like vim-plug by:

        Plug 'Shougo/unite.vim'
        Plug 'chemzqm/redismru.vim'

* CD to the project root and run:

        npm install

##🚧Configuration

* **redismru_host** for redis host to connent (default 127.0.0.1).
* **redismru_port** for redis port to connent (default 6379).
* **redismru_key** for redis key to use for MRU list (default 'vimmru').
* **redismru_limit** for limit the count for MRU list load and validat
  (should no more than 2000)

##🍚Usage

* Open unite source with redismru source like:

        Unite redismru

* Open unite redismru source with files limit in current cwd:

        Unite redismru:.

* Validate all mru files manully:

        :MruValidate

_validate would start async when vim exit, so you normally don't need this_

see `h:redismru` to learn more.

## License

MIT
