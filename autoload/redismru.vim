if !has('job') && !has('nvim') | finish | endif

let s:nvim_jobcontrol = has('nvim')
let s:vim_jobcontrol = !has('nvim') && has('job') && has('patch-7-4-1590')

let g:redismru_host = get(g:, 'redismru_host', '127.0.0.1')
let g:redismru_port = get(g:, 'redismru_port', 6379)
let s:command = 'redis-cli -h '.g:redismru_host. ' -p '.g:redismru_port
let s:rediskey = get(g:, 'redismru_key', 'vimmru')
let s:mrulimit = get(g:, 'redismru_limit', 2000)
let s:loaded = 0
let s:validate_prog = expand('<sfile>:h:h').'/bin/clean.js'

let s:mru_files = []

function! s:warp_vim_startjob(argv, opts)
    let obj = {}
    let obj._argv = a:argv
    let obj._opts = a:opts

    function! obj._out_cb(job_id, data)
        if has_key(self._opts, 'on_stdout')
            call self._opts.on_stdout(a:job_id, [a:data], 'stdout')
        endif
    endfunction

    function! obj._err_cb(job_id, data)
        if has_key(self._opts, 'on_stderr')
            call self._opts.on_stderr(a:job_id, [a:data], 'stderr')
        endif
    endfunction

    function! obj._exit_cb(job_id, data)
        if has_key(self._opts, 'on_exit')
            call self._opts.on_exit(a:job_id, [a:data], 'exit')
        endif
    endfunction

    let obj = {
        \ 'argv': a:argv,
        \ 'opts': {
            \ 'mode': 'nl',
            \ 'out_cb': obj._out_cb,
            \ 'err_cb': obj._err_cb,
            \ 'exit_cb': obj._exit_cb,
            \ }
        \ }

    return obj
endfunction

" async load
function! redismru#load()
  if s:loaded
    let s:mru_files = []
  endif
  let g:called = 1
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
  let g:action = self.action
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

let s:job_id_counter = 0

function! s:jobstart(argv, opts) abort
    if s:nvim_jobcontrol
        return jobstart(a:argv, a:opts)
    elseif s:vim_jobcontrol
        let l:wrapped = s:warp_vim_startjob(a:argv, a:opts)
        return job_start(l:wrapped.argv, l:wrapped.opts)
    else
        let s:job_id_counter = s:job_id_counter + 1
        let l:stdout = system(join(a:argv, ' '))
        let l:job_id = 'system_' . s:job_id_counter
        if has_key(a:opts, 'on_stdout')
            call a:opts.on_stdout(l:job_id, split(l:stdout, '\r\?\n', 1), 'stdout')
        endif
        if has_key(a:opts, 'on_exit')
            call a:opts.on_exit(l:job_id, [v:shell_error], 'exit')
        endif
    endif
endfunction
