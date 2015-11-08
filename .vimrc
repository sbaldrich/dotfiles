set nocompatible
"Pathogen to make plugin management less of a pain in the ass
call pathogen#helptags()
call pathogen#infect()

"Change the mapleader to , just because
let mapleader=","

"Mappings for quickly editing/reloading the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

"Hide buffers instead of closing them
set hidden

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
set number
set numberwidth=3

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

"Kill arrows to use Vim like a man
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

"Ignore some extensions when autocompleting
set wildignore=*.swp,*.bak,*.pyc,*.class,*.o,*.h.*,*.aux,*.bbl,*.blg,*.dvi,*.fls,*.fdb_* 

"Don't bust my balls with bells when I make a mistake
set visualbell
set noerrorbells

"Rules based on filetype
filetype plugin indent on
autocmd filetype python set expandtab

"Key mappings
"<Ctrl-l> redraws the screen and removes any search highlighting.
nnoremap <silent> <C-l> :nohl<CR><C-l>

"Toogle paste mode with F2
set pastetoggle=<F2>

"F5 to show current buffers
nnoremap <F5> :buffers<CR>:buffer<Space>

"Fix problems with backspace
set backspace=indent,eol,start

"Viewport scrolling is 'faster'
nnoremap <C-e> 2<C-e>
nnoremap <C-y> 2<C-y>

"PLUGIN CONFIGURATIONS
"vim-airline
let g:airline#extensions#tabline#enabled = 1
