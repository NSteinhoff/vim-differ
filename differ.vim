" Vim plugin for diffing files against a chosen git ref.
" Last Change:      2019 Sep 06
" Maintainer:       Niko Steinhoff <niko.steinhoff@gmail.com>
" License:          This file is placed in the public domain.

" if exists("g:loaded_beg2differ")
"     finish
" endif
" let g:loaded_beg2differ = 1

aug insta_source
    au!
    au BufWritePost differ.vim source differ.vim
aug END

if !executable('git')
    echo "You must have git installed to use this plugin"
    finish
endif

function! s:git_status()
    return system('git status')
endfunction

function! s:git_refs()
    return systemlist("git branch -a --format '%(refname:short)'")
endfunction

function! s:git_mergebase(this, ...)
    let that = a:0 == 0 ? "HEAD" : a:1
    return trim(system("git merge-base ".a:this." ".that))
endfunction

function! s:git_cfiles(...)
    let ref = a:0 == 0 ? "HEAD" : a:1
    return systemlist("git diff --name-only ".ref)
endfunction

function! s:git_ctitle(ref)
    return system("git log -n1 --format='%s - %cr' ".a:ref)
endfunction

function! s:select_ref()
    let refs = s:git_refs()
    let items = []
    for i in range(0, len(refs)-1)
        call add(items, " " . (i+1) . ": " . refs[i])
    endfor
    return refs[inputlist(["Pick a ref:"] + items) - 1]
endfunction

function! s:open_preview(fname)
    let ft = &ft
    exe 'pedit '.a:fname
    wincmd P | wincmd H | let &filetype = ft | diffthis | wincmd p | diffthis
endfunction

function! s:git_original(fname, ...)
    let ref = a:0 == 0 ? "HEAD" : a:1
    return systemlist('git show '.ref.':'.a:fname)
endfunction

function! s:preview_when_changed()
    if &previewwindow || &diff || &readonly
        return 0
    endif

    if count(s:git_cfiles(), expand('%')) == 0
        return 0
    endif
    let original = s:git_original(expand('%'))
    let tmp = '/tmp/diff-'.localtime()
    call writefile(original, tmp)
    call s:open_preview(tmp)
    return 1
endfunction

function! differ#toggle()
    if !exists('g:differ_enabled')
        if s:preview_when_changed() > 0
            let g:differ_enabled = 1
        else
            echo "Nothing to diff"
        endif
    else
        unlet g:differ_enabled
        pclose
        diffoff!
    endif
endfunction

command! D call differ#toggle()
nnoremap <leader>d :D<CR>
