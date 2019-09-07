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
    au BufWritePost <buffer> source %
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

function! s:git_current_branch()
    return trim(system("git rev-parse --abbrev-ref HEAD"))
endfunction

function! s:git_mergebase(this, ...)
    let that = a:0 == 0 ? "HEAD" : a:1
    return trim(system("git merge-base ".a:this." ".that))
endfunction

function! s:git_cfiles(ref)
    return systemlist("git diff --name-only ".a:ref)
endfunction

function! s:git_ctitle(ref)
    return trim(system("git log -n1 --format='%s (%cr)' ".a:ref))
endfunction

function! s:git_csummary(ref)
    return trim(system("git log -n1 --format='%h - %s (%cr)' ".a:ref))
endfunction

function! s:git_original(fname, ref)
    return systemlist('git show '.a:ref.':'.a:fname)
endfunction

function! s:git_patch(fname, ref)
    return systemlist('git diff '.a:ref.' -- '.a:fname)
endfunction

function! s:git_patch_all(ref)
    return systemlist('git diff '.a:ref)
endfunction

function! s:select_ref()
    let refs = s:git_refs()
    let items = ["Pick a ref:"]
    for i in range(0, len(refs)-1)
        let num = i+1
        let ref = refs[i]
        let msg = s:git_ctitle(ref)
        call add(items, ' '.num.') '.ref.': '.msg)
    endfor
    let choice = inputlist(items) | echo "\n"

    if choice <= 0
        echo "Okay then..."
        return ""
    elseif choice >= len(items)
        echo "Sorry! '".choice."' is not a valid choice!"
        return ""
    else
        return refs[choice-1]
    endif
endfunction

function! s:target_ref(target)
    if a:target != ""
        return a:target
    elseif exists('s:target_ref') && s:target_ref
        return s:target_ref
    else
        return 'HEAD'
endfunction

function! s:load_original(fname, ref, ft)
    setlocal buftype=nofile bufhidden=wipe noswapfile | let &l:ft = a:ft
    au BufUnload,BufWinLeave <buffer> diffoff!

    let original = s:git_original(a:fname, a:ref)
    call append(0, original)

    diffthis | wincmd p | diffthis
endfun

function! s:load_patch(fname, ref)
    setlocal buftype=nofile bufhidden=wipe noswapfile ft=diff

    let patch = s:git_patch(a:fname, a:ref)
    call append(0, patch)
    wincmd p
endfun

function! s:load_patch_all(ref)
    setlocal buftype=nofile bufhidden=wipe noswapfile ft=diff

    let patch = s:git_patch_all(a:ref)
    call append(0, patch)
endfun

function! differ#diff(target)
    let ref = s:target_ref(a:target)
    let ft = &ft
    let fname = expand('%')
    execute 'vnew [DIFF:'.ref.'] '.fname.': '. s:git_ctitle(ref)
    call s:load_original(fname, ref, ft)
endfunction

function! differ#patch(target)
    let ref = s:target_ref(a:target)
    let fname = expand('%')
    execute 'new [PATCH:'.ref.'] '.fname.': '. s:git_ctitle(ref)
    wincmd K | resize 9
    call s:load_patch(fname, ref)
endfunction

function! differ#patch_all(target)
    let ref = s:target_ref(a:target)
    execute 'tabnew __PATCH__' . ref
    call s:load_patch_all(ref)
endfunction

function! differ#list_refs(A,L,P)
    let refs = s:git_refs()
    return refs
endfun

function! differ#set_target(target)
    let s:target_ref = a:target == "" ? s:select_ref() : a:target
    if s:target_ref != ""
        echo "Setting diff target ref to '".s:target_ref."'."
    else
        echo "Using default target ref."
    endif
endfunction

function! differ#status()
    echo s:git_status()
    let local = "HEAD"
    let remote = s:target_ref("")
    echo "\n---\n"
    echo "LOCAL: ".s:git_csummary(local)
    echo "REMOTE: ".remote.' - '.s:git_csummary(remote)
endfunction

command! -complete=customlist,differ#list_refs -nargs=? Diff call differ#diff(<q-args>)
command! -complete=customlist,differ#list_refs -nargs=? Patch call differ#patch(<q-args>)
command! -complete=customlist,differ#list_refs -nargs=? PatchAll call differ#patch_all(<q-args>)
command! -complete=customlist,differ#list_refs -nargs=? DiffTarget call differ#set_target(<q-args>)
command! DiffStatus call differ#status()
