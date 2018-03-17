# Redismru.vim

[![](http://img.shields.io/github/issues/neoclide/redismru.vim.svg)](https://github.com/neoclide/redismru.vim/issues)
[![](http://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![](https://img.shields.io/badge/doc-%3Ah%20redismru.txt-red.svg)](doc/redismru.txt)

Most recently used files plugin for vim8 & [Neovim](https://github.com/neovim/neovim)
using Redis and job-control feature.

Redismru also perform MRU list load on CursorHold, this makes work with multiply
vim instances easier.

## Why Redismru?

* No performance influence on startup, very fast async load.
* Sync file list across all vim instance.
* Ignore pattern support.
* Support limit results to specific directory and record remove.
* Automatic file existing validation on vim leave (default).

## Usage

You can also limit the files shown by Redismru by pass a directory as first
unite argument, like:

``` vim
Unite redismru
```

Or use [denite.nvim](https://github.com/Shougo/denite.nvim)

``` vim
" Search all recently files
Denite redis_mru
" Search recently files of current CWD
Denite redis_mru:.
```

**Note**, async file load at startup and would cost 10~100ms, you
can't get the list before it finish.

## 🔍Install

* install [redis](https://redis.io/) and [nodejs](https://nodejs.org) with command like:

        brew install redis
        brew install node

_node script is used for async file validate (started on vim leave)_

* install this plugin and denite.nvim/unite.vim with plugin manager like vim-plug by:

        Plug 'Shougo/unite.vim'
	      Plug 'neoclide/redismru.vim', {do: 'npm install'}

* CD to the project root and run:

        npm install

## 🚧Configuration

* **g:redismru_disable_auto_validate** set to `1` if you want to disable
  validation on vim leave.
* **g:redismru_disable_sync** set to `1` if you want to disable automatic sync
  on CursorHold event.
* **g:redismru_ignore_pattern** vim regex for ignored files, default see `:h g:redismru_ignore_pattern`.
* **g:redismru_host** for redis host to connent (default 127.0.0.1).
* **g:redismru_port** for redis port to connent (default 6379).
* **g:redismru_key** for redis key to use for MRU list (default 'vimmru').
* **g:redismru_limit** for limit the count for MRU list load and validation
  (should no more than 2000).

## 🍚Usage

If you use [denite.nvim](https://github.com/Shougo/denite.nvim), you can add
keymap like:

      nnoremap <silent> <space>r  :<C-u>Denite redis_mru<cr>
      nnoremap <silent> \r        :<C-u>Denite redis_mru:.<cr>

* Open unite source with redismru source like:

        Unite redismru

* Open unite redismru source with files limit in current cwd:

        Unite redismru:.

* Validate all mru files manully:

        :MruValidate

_validation would start async when vim exit, so you normally don't need this_

see `h:redismru` to learn more.
