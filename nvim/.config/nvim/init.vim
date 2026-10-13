" ~/.config/nvim/init.vim
"
" Neovim config, migrated from ~/.vimrc.
" Many classic vimrc settings (nocompatible, syntax on, filetype plugin indent
" on, hlsearch, incsearch, autoread, wildmenu, ...) are Neovim defaults and
" are intentionally left out. See :help vim-differences

" ============================================================================
" GENERAL
" ============================================================================

" <leader> is the prefix key for custom mappings. Set it before any mapping
" that uses it, since mappings read its value when they are defined.
let mapleader = ","

" Edit / reload this config file ($MYVIMRC points to init.vim)
nnoremap <silent> <leader>ev :e $MYVIMRC<CR>
nnoremap <silent> <leader>sv :so $MYVIMRC<CR>

" Quick quit / save. <leader>Q has no <CR> on purpose: press Enter to confirm
" quitting without saving.
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :q!
nnoremap <leader>w :w<CR>

" Cycle through open buffers
nnoremap <C-n> :bnext<CR>
nnoremap <C-p> :bprevious<CR>

" ============================================================================
" UI
" ============================================================================

" Hybrid line numbers: absolute number on the cursor line, relative elsewhere
" (handy for jumps like 5j or d3k)
set number relativenumber
set numberwidth=6

" Briefly jump to the matching bracket when typing a closing one
set showmatch

" Don't wrap long lines; scroll horizontally instead
set nowrap

" Prefix shown on wrapped continuation lines (only visible if wrap is on).
" The escaped space after the arrow is intentional.
set showbreak=↪\ 

" Optional: highlight the cursor line / show invisible characters
"set cursorline
"set list
"set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·

" ============================================================================
" INDENTATION
" ============================================================================

set tabstop=2       " a <Tab> character displays as 2 columns
set shiftwidth=2    " >>, <<, and autoindent use 2 columns
set shiftround      " round >> / << to a multiple of shiftwidth
set copyindent      " new lines copy the previous line's indent characters
                    " (tabs vs spaces) instead of guessing

" ============================================================================
" FILES
" ============================================================================

set noswapfile      " no .swp files (you lose crash recovery for unsaved work)
set autowrite       " save automatically when switching buffers with :bnext,
                    " :make, etc. (so <C-n>/<C-p> never complain)

" ============================================================================
" SEARCH
" ============================================================================

set ignorecase      " case-insensitive search...
set smartcase       " ...unless the pattern contains an uppercase letter

" Clear search highlighting (Neovim's default <C-l> does this too, but
" <C-l> is remapped to split navigation below)
nnoremap <silent> <leader>l :nohlsearch<CR>

" ============================================================================
" EDITING
" ============================================================================

" Q formats text to fit textwidth: the selection in visual mode, or the
" current paragraph in normal mode. This overrides Neovim's default Q
" (replay the last recorded macro); use @@ for that instead.
vnoremap Q gq
nnoremap Q gqap

" Disable arrow keys to build hjkl habits
noremap <up> <nop>
noremap <down> <nop>
noremap <left> <nop>
noremap <right> <nop>

" Yank the whole buffer to the system clipboard ("+ register) without moving
" the cursor. Requires a clipboard tool (xclip / wl-clipboard on Linux).
nnoremap <silent> <leader>Y :%y+<CR>

" Scroll the viewport 2 lines at a time instead of 1
nnoremap <C-e> 2<C-e>
nnoremap <C-y> 2<C-y>

" ============================================================================
" WINDOWS / SPLITS
" ============================================================================

" Move between splits with Ctrl + hjkl instead of Ctrl-w + hjkl
nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-L> <C-W>l
nnoremap <C-H> <C-W>h

" New splits open below / to the right, instead of above / to the left
set splitbelow
set splitright

" ============================================================================
" FILE FINDING (built-in)
" ============================================================================

" Search all subdirectories of the working directory recursively for :find,
" gf (go to file under cursor), and <C-w>f. Example: :find *test*<Tab>
" Can be slow in very large projects (e.g. with node_modules).
set path+=**

" File patterns to exclude from filename completion (:find, :e, etc.)
set wildignore=*.swp,*.bak,*.pyc,*.class,*.o,*.h.*,*.aux,*.bbl,*.blg,*.dvi,*.fls,*.fdb_*

" ============================================================================
" PLUGINS (vim-plug; installed to ~/.local/share/nvim/plugged)
" ============================================================================
" After changing this list: :PlugInstall to install, :PlugClean to remove
" plugins no longer listed, :PlugUpdate to update.

call plug#begin()

Plug 'nvim-lua/plenary.nvim'               " Lua utility library, required by telescope
Plug 'nvim-telescope/telescope.nvim'       " fuzzy finder (files, grep, buffers, ...)
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
                                           " compiled sorter for faster matching;
                                           " needs make + a C compiler
Plug 'ayu-theme/ayu-vim' " or other package manager
" Disabled for now. Uncomment the Plug line AND its config block below.
"Plug 'sirver/ultisnips'                   " snippets; needs: pip install pynvim
"Plug 'stevearc/oil.nvim'                  " file explorer: edit directories as buffers
"Plug 'nvim-lualine/lualine.nvim'          " statusline + buffer tabline
"Plug 'stevearc/conform.nvim'              " formatting via external formatters

call plug#end()

set termguicolors     " enable true colors support
let ayucolor="mirage" " for mirage version of theme
"let ayucolor="dark"   " for dark version of theme
colorscheme ayu
" ============================================================================
" PLUGIN CONFIG
" ============================================================================
" Plugin setup goes after plug#end(), which is when plugins are loaded.
" Lua plugins are configured inside lua << EOF ... EOF blocks.

" --- Telescope -------------------------------------------------------------
" live_grep requires ripgrep (rg); fd is optional but speeds up find_files.
" Inside a picker: <C-n>/<C-p> to move, <CR> to open, <C-x>/<C-v> to open
" in a split / vertical split, <Esc> to close.
lua << EOF
require('telescope').setup()
-- pcall: don't error out if fzf-native failed to build
pcall(require('telescope').load_extension, 'fzf')
EOF

nnoremap <leader>ff :Telescope find_files<CR>
nnoremap <leader>fF :Telescope find_files hidden=true no_ignore=true<CR>
nnoremap <leader>fg :Telescope live_grep<CR>
nnoremap <leader>fb :Telescope buffers<CR>
nnoremap <leader>fh :Telescope help_tags<CR>
nnoremap <leader>fr :Telescope oldfiles<CR>

" --- UltiSnips -------------------------------------------------------------
" <Tab> expands a snippet and jumps to the next placeholder; <S-Tab> goes back.
"let g:UltiSnipsExpandTrigger = '<tab>'
"let g:UltiSnipsJumpForwardTrigger = '<tab>'
"let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'
"nnoremap <silent> <leader>ued :UltiSnipsEdit<CR>

" --- Oil -------------------------------------------------------------------
" '-' opens the current file's directory as an editable buffer. Rename or
" delete files by editing lines, then :w to apply. (Not <leader>e, which
" would make <leader>ev wait for a timeout.)
"lua require('oil').setup()
"nnoremap <silent> - :Oil<CR>

" --- Lualine ---------------------------------------------------------------
" Icons and powerline separators are off so it works without a Nerd Font.
" The tabline lists open buffers (pairs with <C-n>/<C-p>).
"lua << EOF
"require('lualine').setup({
"  options = {
"    icons_enabled = false,
"    section_separators = '',
"    component_separators = '|',
"  },
"  tabline = { lualine_a = { 'buffers' } },
"})
"EOF

" --- Conform ---------------------------------------------------------------
" Formatters listed here must be installed separately (black, stylua, ...).
" lsp_format = 'fallback' uses a language server's formatter if no external
" one is configured for the filetype.
"lua << EOF
"require('conform').setup({
"  formatters_by_ft = {
"    python = { 'black' },
"    lua = { 'stylua' },
"  },
"})
"EOF
"nnoremap <silent> <leader>cf :lua require('conform').format({ lsp_format = 'fallback' })<CR>
"vnoremap <silent> <leader>cf :lua require('conform').format({ lsp_format = 'fallback' })<CR>
