set nocompatible

" GENERAL

"Change the mapleader to , just because
let mapleader=","

"Mappings for quickly editing/reloading the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>
nmap <silent> <leader>ei3 :e ~/.config/i3/config<CR>
nmap <silent> <leader>ttj :0r ~/code/cp/templates/template.java<CR>/ContestIO<CR>zf%<CR>/::template-entr<CR>zzS

"Spelling

"setlocal spell
"set spelllang=en_gb
"inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u

" BUFFERS
"Hide buffers instead of closing them
set hidden

nnoremap <leader>w :w<CR>

nnoremap <C-n> :bnext<CR>
nnoremap <C-p> :bprevious<CR>

" Show the current command
set showcmd

"Always show status line
set laststatus=2

"Syntax highlighting + Color scheme
syntax enable
"set background=light "commented out bc it's not working
"colorscheme solarized

"Autoread changes file changes outside vim
set autoread

"Always show position
set ruler

"Show line numbers
set relativenumber number
set numberwidth=6

"Tabs
set smarttab
set tabstop=4
set shiftwidth=4
set shiftround
set autoindent
set copyindent

"Show matching parenthesis
set showmatch

"Show where the cursor is
"set cursorline
set list
"set listchars=tab:>-,trail:.,nbsp:~
set showbreak=↪\ 
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·


"Do not create swap nor backup files
set noswapfile
set nobackup

"Don't wrap lines
set nowrap

"Searching
"Show incremental search matches
set incsearch
set ignorecase
set smartcase
set hlsearch

"Formatting
vmap Q gq "Format selection
nmap Q gqap "Format paragraph

"Kill arrows to use Vim like you're supposed to
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

"Ignore some extensions when autocompleting
set wildignore=*.swp,*.bak,*.pyc,*.class,*.o,*.h.*,*.aux,*.bbl,*.blg,*.dvi,*.fls,*.fdb_* 

"No bells
set novisualbell
set noerrorbells

"Rules based on filetype
filetype plugin indent on
autocmd filetype python set expandtab

"Key mappings
"<Ctrl-l> redraws the screen and removes any search highlighting.
noremap <leader>l :nohl<CR>

"More natural split navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

"Split opening that actually makes sense
set splitbelow
set splitright

"Toogle paste mode with F2
set pastetoggle=<F2>
"Yank to clipboard with <C-y>
map <C-y> :w !xclip -sel c <CR><CR>

"Save using F3
nnoremap <F3> :w<CR>
inoremap <F3> <ESC>:w<CR>

"F5 to show current buffers
nnoremap <F5> :buffers<CR>:buffer<Space>

"Fix problems with backspace
set backspace=indent,eol,start

"Viewport scrolling is 'faster'
nnoremap <C-e> 2<C-e>
nnoremap <C-y> 2<C-y>


"Lang specific stuff
autocmd Filetype java set makeprg=javac\ %
autocmd Filetype python set makeprg=python\ %

set errorformat=%A%f:%l:\ %m,%-Z%p^,%-C%.%#
map <F9> :make<Return>:copen<Return>
map <F10> :cprevious<Return>
map <F11> :cnext<Return>
map <F12> :cclose<CR>
set autowrite



"Do what plugings do with just vim
"  File finding
set path+=**
set wildmenu
inoremap {<CR> {<CR>}<ESC>O

"Setup some minimal plugins
call plug#begin('~/.vim/plugged')

Plug 'lervag/vimtex'
Plug 'sirver/ultisnips'
"Plug 'honza/vim-snippets'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

"vim-tex config
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0
set conceallevel=1
let g:tex_conceal='abdmg'

let g:UltiSnipsExpandTrigger = '<tab>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'

let g:vimtex_compiler_latexmk = {
    \ 'options' : [
    \   '-pdf',
    \   '-shell-escape',
    \   '-verbose',
    \   '-file-line-error',
    \   '-synctex=1',
    \   '-interaction=nonstopmode',
    \ ],
    \}

"Plugin configs
"vim-airline
let g:airline#extensions#tabline#enabled = 1

nmap <silent> <leader>ued :UltiSnipsEdit<CR>

"NETRW CONFIG
let g:netrw_liststyle = 3
let g:netrw_banner = 0
let g:netrw_browse_split = 2
let g:netrw_winsize = 25
