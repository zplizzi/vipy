" PYTHON FILE MAPPINGS
nnoremap <silent> <buffer> <leader>5 :wa<CR>:py3 run_this_file()<CR><ESC>l
vnoremap <silent> <buffer> <leader>5 y:py3 run_these_lines()<CR><ESC>
" TODO: make K print currentword? in the buffer
" noremap  <silent> K :py3 get_doc_buffer()<CR>
nnoremap <silent> <buffer> <F9> :py3 run_this_line()<CR><ESC>j
noremap  <silent> <buffer> <F12> :py3 toggle_vib()<CR>
inoremap <silent> <buffer> <F12> <ESC>:py3 toggle_vib()<CR>
nnoremap <silent> <buffer> <F10> :py3 db_step()<CR>
nnoremap <silent> <buffer> <F11> :py3 db_stepinto()<CR>
nnoremap <silent> <buffer> <C-F11> :py3 db_stepout()<CR>
nnoremap <silent> <buffer> <leader>% :py3 db_quit()<CR>

" CELL MODE MAPPINGS
nnoremap <expr> <buffer> <silent> <S-CR> pumvisible() ? "\<ESC>:py3 print_completions(invipy=False)\<CR>i" : "\<ESC>:py3 run_cell()\<CR>\<ESC>i"
nnoremap <silent> <buffer> <C-CR> :py3 run_cell(progress=True)<CR><ESC>
inoremap <expr> <silent> <buffer> <S-CR> pumvisible() ? "\<ESC>:py3 print_completions(invipy=False)\<CR>i" : "\<ESC>:py3 run_cell()\<CR>\<ESC>i"
inoremap <silent> <buffer> <C-CR> <ESC>:py3 run_cell(progress=True)<CR><ESC>i
vnoremap <silent> <buffer> <S-CR> :py3 run_cell()<CR><ESC>gv
vnoremap <silent> <buffer> <C-CR> :py3 run_cell(progress=True)<CR><ESC>gv
