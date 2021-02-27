"let g:ycm_python_binary_path = system("poetry env list --full-path")[:-2]
let g:ycm_autoclose_preview_window_after_completion = 1
let g:python3_host_prog='/usr/bin/python3'
"let g:python3_host_prog=system("poetry env list --full-path")[:-2]

" no preview window on top of a file
set completeopt-=preview
set completeopt-=menuon
let g:ycm_add_preview_to_completeopt = 0

nnoremap ,d :YcmCompleter GoToDefinitionElseDeclaration<CR>
