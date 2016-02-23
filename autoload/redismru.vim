if !has('job') && !has('nvim') | finish | endif
let g:redismru_host = '127.0.0.1'
let g:redismru_port = 6379
let s:command = 'redis-cli -h '.get(g:, 'redismru_host','127.0.0.1'). ' -p '.get(g:, 'redismru_port', 6379)
let s:rediskey = get(g:, 'redismru_key', 'vimmru')
let s:mrulimit = get(g:, 'redismru_limit', 2000)
let s:loaded = 0
let s:validate_prog = expand('<sfile>:h:h').'/bin/validate.js'

let s:mru_files = []

" async load
function! redismru#load()
  if s:loaded
    let s:mru_files = []
  endif
  call s:redis('load', 'ZREVRANGE '.s:rediskey.' 0 '.s:mrulimit.'|sed ''s/^\d+)\s"\(.*\)"$/\1/''')
endfunction

function! redismru#files()
  return s:mru_files
endfunction

" validate files at background
function! redismru#validate(opts)
  call s:jobstart('node '.s:validate_prog,  {
    \ 'on_stderr': function('s:OnError'),
    \ 'on_exit': function('s:OnExit'),
    \ 'action': 'validate',
    \ 'load': a:opts.load,
    \ 'detach': a:opts.detach,
    \})
endfunction

function! redismru#append(file)
  let path = fnamemodify(a:file, ':p')
  call s:redis('add', 'ZADD '.s:rediskey.' '
        \.localtime().' '.fnameescape(path))
  let idx = index(s:mru_files, path)
  if idx != -1
    call remove(s:mru_files, idx)
  endif
  let s:mru_files = [path] + s:mru_files
endfunction

" remove file from redis and local list
function! redismru#remove(file)
  let path = fnamemodify(a:file, ':p')
  call s:redis('remove', 'ZREM '.s:rediskey.' '.path)
  let idx = index(s:mru_files, path)
  if idx != -1
    call remove(s:mru_files, idx)
  endif
endfunction

" call redis with command args
function! s:redis(action, args)
  let cmd = s:command . ' ' . a:args
  call s:jobstart(cmd, {
    \ 'on_stderr': function('s:OnError'),
    \ 'on_stdout': function('s:OnData'),
    \ 'on_exit': function('s:OnExit'),
    \ 'action': a:action,
    \})
endfunction

function! s:OnError(job_id, data, event) dict
  echohl Error | echon a:data | echohl None
endfunction

function! s:OnData(job_id, data, event) dict
  if self.action ==# 'load'
    let data = type(a:data) == 1 ? [data] : copy(a:data)
    for path in data
      if index(s:mru_files, path) == -1
        call add(s:mru_files, path)
      endif
    endfor
  endif
endfunction

function! s:OnExit(job_id, data, event) dict
  if self.action ==# 'load'
    let s:loaded = 1
  elseif self.action ==# 'validate' && self.load == 1
    call redismru#load()
  endif
endfunction

function! s:jobstart(cmd, opts)
  if has('nvim')
    let opts = copy(a:opts)
   else
     let opts = {
           \ 'err-cb': a:opts.on_stderr,
           \ 'out-cb': a:opts.on_stdout,
           \ 'exit-cb': a:opts.on_exit,
           \}
     for key in a:opts
       if index(['on_stderr', 'on_stdout', 'on_exit'], key) == -1
         let opts[key] = a:opts[key]
       endif
     endfor
  endif
  let start = has('nvim') ? 'jobstart' : 'job_start'
  execute 'call '.start.'(a:cmd, opts)'
endfunction
