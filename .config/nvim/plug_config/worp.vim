let g:ale_linters = {
\   'python': ['pylint'],
\   'go': ['gopls'],
\}
let g:ale_fixers = {
\    'python': ['black'],
\}
let g:ale_python_pylint_options = '--rcfile $HOME/.pylintrc_google'
"--load-plugins=pylint_flask
"--load-plugins=pylint_django
nmap <silent> <M-k> <Plug>(ale_previous_wrap)
nmap <silent> <M-j> <Plug>(ale_next_wrap)
