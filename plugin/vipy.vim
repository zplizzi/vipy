" Vim plugin for integrating IPython into vim for fast python programming
" Last Change: ___
" Maintainer: J. David Giese <johndgiese@gmail.com>
" License: This file is placed in the public domain.

if !has('python3')
    " exit if python is not available.
    echoe('In order to use vipy you must have a version of vim or gvim that is compiled with python3 support.')
    finish
endif

let s:vipy_location=expand("<sfile>:h:p")


function! SourceMain()
    echom "Starting VIPY! This may take a few seconds..."
    execute "source " . s:vipy_location . "/../main.vim"
endfunction

" Define startup commands (the main portion of the code is sourced separately
" for startup speed
noremap <silent> <Leader>p :call SourceMain()<CR>:py3 vipy_startup()<CR>
inoremap <silent> <Leader>p :call SourceMain()<CR>:py3 vipy_startup()<CR>
vnoremap <silent> <Leader>p :call SourceMain()<CR>:py3 vipy_startup()<CR>
