" Vim plugin for diffing files against a chosen git ref.
" Last Change:      2019 Sep 06
" Maintainer:       Niko Steinhoff <niko.steinhoff@gmail.com>
" License:          This file is placed in the public domain.

" if exists("g:loaded_beg2differ")
"     finish
" endif
" let g:loaded_beg2differ = 1

if !executable('git')
    echo "You must have git installed to use this plugin"
    finish
endif

function! s:git_status()
    return system('git status')
endfunction

function! s:list_branches()
    return systemlist('git branch')
endfunction

command! Branches :call s:list_branches()

