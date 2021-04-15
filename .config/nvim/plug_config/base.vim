set exrc                          " source vimrc in proj dir
set guicursor=                    " fat cursor
"set hidden                       " change buffer without save
set noerrorbells
set nowrap                        " allows to write on one long line
set nobackup
set nowritebackup
set noswapfile
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set incsearch                     " set curson upon writing when search
"set termguicolors                " with tmux shows colors too acid
set t_Co=256                      " tmux color problem
set background=dark
set scrolloff=8                   " show more code when N lines away
"set viminfo='30                  " browse oldfiles limit (outdited since using :History)
"set autochdir
set nocompatible
set clipboard=unnamedplus         " yank into clipboard
set hlsearch
set nowrapscan                    " prevent search being looped
set backspace=indent,eol,start    " backspace behave as expect
set path=$PWD/**                  " cool file finding mechanism
set wildmenu
set wildignore=*.pyc
set laststatus=2                  " always show status line
set statusline=%f\ -\ %y
set cmdheight=2                   " height of status line
set shortmess+=cI                 " don't pass messages to |ins-completion-menu|
set updatetime=50                 " update more frequently

let g:python3_host_prog="/usr/bin/python"
let mapleader = ","

" disable F1
nmap <F1> <nop>
nmap <M-F1> <nop>

vnoremap < <gv " continue visual selecting after shiftwidh
vnoremap > >gv
vnoremap <leader>p "_dP   " using this command, can past multiple times without re-filling yank history

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" save as root
cmap w!! w !sudo tee > /dev/null %
noremap <silent><Leader>/ :nohls<CR>  " disable highlighting

" template pasting
nnoremap ,models :-1read $XDG_CONFIG_HOME/nvim/templates/flask-models<CR>
nnoremap ,api :-1read $XDG_CONFIG_HOME/nvim/templates/flask-api<CR>

call plug#begin('~/.config/nvim/plugged')

Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'fannheyward/coc-pyright', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}
Plug 'mbbill/undotree'
Plug 'airblade/vim-gitgutter'
Plug 'morhetz/gruvbox'
" Telescope
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
" END Telescope

" DEPRECATED
"Plug 'dense-analysis/ale'
"Plug 'ycm-core/YouCompleteMe', {'do': './install.py'}
"Plug 'git://github.com/frioux/vim-lost'
"Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
" END deprecated

call plug#end()

" 'syntax' and 'filetype plugin indent' need to be overrided only after call plug#begin()
" typescript syntax fix https://github.com/neovim/neovim/issues/14356#issuecomment-820429884
syntax on sync fromstart
filetype plugin indent on
autocmd vimenter * ++nested colorscheme gruvbox

" ripgrep
"command! -bang -nargs=* Find call fzf#vim#grep('rg -tpy -tjs --column --line-number --no-heading --fixed-strings --ignore-case --follow --color "always" '.shellescape(<q-args>).'| tr -d "\017"', 1, <bang>0)
function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg -tpy -tjs -tts --sort-files --column --line-number --no-heading --color=always --smart-case --fixed-strings --follow --glob="!*lib/" -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction
command! -nargs=* -bang Find call RipgrepFzf(<q-args>, <bang>0)

" start cursor from a previous place
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" yaml smart indent
au! BufNewFile,BufReadPost *.{yaml,yml} set filetype=yaml
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType javascript setlocal ts=4 sts=4 sw=4 expandtab

" py specific
"autocmd FileType python set colorcolumn=80 " show red line on 80

" already enabled somewhere
"command DiffOrig vert new | set buftype=nofile | read ++edit # | 0d_ | diffthis | wincmd p | diffthis

" Golang
let g:go_def_mode='gopls'
let g:go_info_mode='gopls'

" run, depend on shebang
nnoremap <Leader>r :w \| !clear && echo "\n" && ./%<CR>

" disable unconvenient mappings
command! -nargs=* W w

" show trailing whitespaces as red marks
au BufNewFile,BufRead * let b:mtrailingws=matchadd('ErrorMsg', '\s\+$', -1)

" shortcut to base.vim
let $RC="$XDG_CONFIG_HOME/nvim/plug_config/base.vim"
let $RTP=split(&runtimepath, ',')[0]

" Undotree
nnoremap <F5> :UndotreeToggle<CR>  " toggle undotree

if has('persistent_undo')
   let target_path = expand('~/.undodir')

    " create the directory and any parent directories
    " if the location does not exist.
    if !isdirectory(target_path)
        call mkdir(target_path, "p", 0700)
    endif

    let undodir = target_path
    set undofile
endif


" DEPRECATED

" use History from fzf
"command! Oldfiles call fzf#run({
"\  'source':  v:oldfiles,
"\  'sink':    'e',
"\  'options': '-m -x +s',
"\  'down':    '40%'})
