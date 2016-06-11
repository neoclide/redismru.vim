let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#redismru#define()
  return s:source
endfunction

let g:redismru_ignore_pattern = get(g:, 'redismru_ignore_pattern',
      \'\~$\|\.\%(o\|exe\|dll\|bak\|zwc\|pyc\|sw[po]\)$'.
      \'\|\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)'.
      \'\|^\%(__\|todo://\|\\\\\|/mnt/\|/media/\|/temp/\|/tmp/\|\%(/private\)\=/var/folders/\)'
      \)

let s:source = {
      \ "name" : "redismru",
      \ "description" : "output redismru",
      \ "hooks" : {},
      \ "action_table" : {},
      \ "default_kind": 'file',
      \ 'ignore_pattern' : g:redismru_ignore_pattern,
      \ "max_candidates" : 200,
      \}

function! s:source.gather_candidates(args, context)
  let home = expand('~')
  if empty(a:args)
    let files = copy(redismru#files())
  else
    let dir = a:args[0]
    let dir = dir ==# '.' ? getcwd() : dir
    let files = filter(copy(redismru#files()), "stridx(v:val, dir) == 0")
  endif
  if empty(files) | return [] | endif
  let base = exists('dir') ? dir : home
  return map(files, "{
      \ 'word': v:val[len(base):],
      \ 'abbr': s:relativePath(v:val, base),
      \ 'action__path': v:val,
      \}")
endfunction

function! s:relativePath(value, base)
  let home = expand('~')
  if a:base == home
    return substitute(a:value, home, '~', '')
  endif
  return '.' . a:value[len(a:base):]
endfunction

let s:source.action_table.delete = {
      \ 'description' : 'delete from redis_mru list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates) abort "{{{
  for candidate in a:candidates
    call redismru#remove(candidate.action__path)
  endfor
endfunction"}}}

function! s:source.hooks.on_init(args, context)
endfunction

function! s:source.hooks.on_close(args, context)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
