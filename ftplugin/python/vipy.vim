" PYTHON FILE MAPPINGS
nnoremap <silent> <buffer> <leader>rf :wa<CR>:py3 run_this_file()<CR><ESC>l
vnoremap <silent> <buffer> <leader>rl :py3 run_these_lines()<CR><ESC>
nnoremap <silent> <buffer> <leader>rl :py3 run_this_line()<CR><ESC>j
nnoremap <silent> <buffer> <leader>rc :py3 run_cell()<CR><ESC>



" TODO: figure out what these do
" CELL MODE MAPPINGS
nnoremap <expr> <buffer> <silent> <S-CR> pumvisible() ? "\<ESC>:py3 print_completions(invipy=False)\<CR>i" : "\<ESC>:py3 run_cell()\<CR>\<ESC>i"
nnoremap <silent> <buffer> <C-CR> :py3 run_cell(progress=True)<CR><ESC>
inoremap <expr> <silent> <buffer> <S-CR> pumvisible() ? "\<ESC>:py3 print_completions(invipy=False)\<CR>i" : "\<ESC>:py3 run_cell()\<CR>\<ESC>i"
inoremap <silent> <buffer> <C-CR> <ESC>:py3 run_cell(progress=True)<CR><ESC>i
vnoremap <silent> <buffer> <S-CR> :py3 run_cell()<CR><ESC>gv
vnoremap <silent> <buffer> <C-CR> :py3 run_cell(progress=True)<CR><ESC>gv
