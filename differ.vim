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
        let g:differ_enabled = s:preview_when_changed()
        echo "Diff enabled!"
    else
        unlet g:differ_enabled
        pclose
        diffoff!
        echo "Diff disabled!"
    endif
endfunction

command! D call differ#toggle()
nnoremap <leader>d :D<CR>

func! PreviewWord()
    if &previewwindow                       " don't do this in the preview window
        return
    endif
    let w = expand("<cword>")               " get the word under cursor
    if w =~ '\a' && strchars(w) >= 3        " if the word contains a letter

        " Delete any existing highlight before showing another tag
        silent! wincmd P                    " jump to preview window
        if &previewwindow                   " if we really get there...
            match none                      " delete existing highlight
            wincmd p                        " back to old window
        endif

        " Try displaying a matching tag for the word under the cursor
        try
            exe 'ptag ' . w
        catch
            return
        endtry

        silent! wincmd P                    " jump to preview window
        if &previewwindow                   " if we really get there...
            if has("folding")
                silent! .foldopen           " don't want a closed fold
            endif
            call search("$", "b")           " to end of previous line
            let w = substitute(w, '\\', '\\\\', "")
            call search('\<\V' . w . '\>')  " position cursor on match

            " Add a match highlight to the word at this position
            hi previewWord term=bold ctermbg=green guibg=green
            exe 'match previewWord "\%' . line(".") . 'l\%' . col(".") . 'c\k*"'
            wincmd p                        " back to old window
        endif
    endif
endfun

augroup preview_tag
    au!
    au! CursorHold * nested call PreviewWord()
augroup END
