if !has('job') && !has('nvim') | finish | endif
if exists('g:did_redismru_loaded') || v:version < 700 || !has('nvim')
  finish
endif
let g:did_redismru_loaded = 1

function! s:append(path)
  if bufnr('%') !=# expand('<abuf>')|| a:path ==# ''
    return
  endif
  if len(&buftype) | return | endif
  let g:path = a:path
  if a:path =~# '\[unite\]' | return | endif
  call redismru#append(expand('%:p'))
endfunction

augroup redismru
  autocmd!
  autocmd VimEnter * call redismru#validate({'detach': 0, 'load': 1})
  autocmd BufEnter,BufWinEnter,BufWritePost *
        \ call s:append(expand('<amatch>'))
  autocmd VimLeavePre *
        \ call redismru#validate({'detach': 1, 'load': 0})
augroup END

command! -nargs=0 MruValidate :call
        \ redismru#validate({'detach':0, 'load': 1})

