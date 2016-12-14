if !has('job') && !has('nvim') | finish | endif
if exists('g:did_redismru_loaded') | finish | endif
let g:did_redismru_loaded = 1

function! s:append(path)
  if bufnr('%') !=# expand('<abuf>')|| a:path ==# ''
    return
  endif
  if &buftype =~# '\v(help|nofile|terminal)' | return | endif
  call redismru#append(expand('%:p'))
endfunction

augroup redismru
  autocmd!
  autocmd VimEnter * call redismru#load()
  if get(g:, 'redismru_disable_sync', 0) != 1
     autocmd CursorHold * call redismru#load()
  endif
  autocmd BufEnter,VimEnter,BufWinEnter,BufWritePost *
        \ call s:append(expand('<amatch>'))
  if get(g:, 'redismru_disable_auto_validate', 0) != 1
    autocmd VimLeavePre *
        \ call redismru#validate({'detach': 1, 'load': 0})
  endif
augroup END

command! -nargs=0 MruValidate :call
        \ redismru#validate({'detach':0, 'load': 1})

