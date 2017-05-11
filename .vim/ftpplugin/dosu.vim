" This has to be the first thing
set nocompatible

" Security
set secure

" Prevent from reccuring itself
set exrc

" ============================================================
" |                                                          |
" |                      PlugImport                          |
" |                                                          |
" ============================================================

call plug#begin('~/.vim/plugged')

	" NERDtree (sidebar panel)
	Plug 'scrooloose/nerdtree'

        " NERD commenter
        Plug 'scrooloose/nerdcommenter'

	" NERDtree-git (Show git differences in NERDtree)
	Plug 'Xuyuanp/nerdtree-git-plugin'

	" Lightline (simplified vesrion of powerline)
	Plug 'itchyny/lightline.vim'

	" Vim-fugitive (git interaction)
	Plug 'tpope/vim-fugitive'

	" EasyMotion
	Plug 'easymotion/vim-easymotion'

	" Vim-twig (syntax, snippets etc.)
	Plug 'evidens/vim-twig'

	" Surround.vim (parenthesis used as object)
	Plug 'tpope/vim-surround'

	" Lexima.vim (auto-complete parenthesis)
	Plug 'cohama/lexima.vim'

        " vim-startify
        Plug 'mhinz/vim-startify'

        " indentline (Show indent lines)
        Plug 'yggdroot/indentline'

        " Ctrl-P (currently best fuzzy finder)
        Plug 'ctrlpvim/ctrlp.vim'

        " Tagbar
        Plug 'majutsushi/tagbar'

        " vim-easytags (needed for Tagbar)
        Plug 'xolox/vim-easytags'

        " vim-misc (needed for vim-easytags)
        Plug 'xolox/vim-misc'

        " vim-devicons
        Plug 'ryanoasis/vim-devicons'

        " vim-github-comment (Github comment straight from vim)
        " Plug 'mmozuras/vim-github-comment'

        " YouCompleteMe
        Plug 'Valloric/YouCompleteMe'

        " Vim-gitignore
        Plug 'gisphm/vim-gitignore'

        " Vim-pandoc
        Plug 'vim-pandoc/vim-pandoc'

        " Vim-pandoc-syntax
        Plug 'vim-pandoc/vim-pandoc-syntax'

call plug#end()
" ============================================================
" |                                                          |
" |                      PlugImport END                      |
" |                                                          |
" ============================================================

" ============================================================
" |                                                          |
" |                   VIM-base-configuration                 |
" |                                                          |
" ============================================================


" >>>>>>>>>>>>>>>>>>>>>> System stuff <<<<<<<<<<<<<<<<<<<<<<

set nomodeline

" Command line history
set history=100

" Cache rendering
set lazyredraw
set ttyfast

" Where to put *.swp files
set dir=~/.vim/tmp

" Where to put backup files
set backup
set backupdir=~/.vim/backup

" Set default clipboard
set clipboard=unnamed

" Set encoding
scriptencoding utf-8
set encoding=utf-8
set termencoding=utf-8
set fileencodings=ucs-bom,utf-8,gbk,big5,latin1

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! %!sudo tee > /dev/null %

" >>>>>>>>>>>>>>>>>>>>>> UI stuff <<<<<<<<<<<<<<<<<<<<<<

" Wrapping
set wrap
set showmatch
set linebreak
set foldenable

set tw=80
set formatoptions+=w

" UI
set ruler

" Activate relative numbering in sidebar
set relativenumber
" Show absolute number on current line
set number

" Wildmode
set wildmode=full
set wildmenu
set wildignorecase
set wildmode=list:longest,full

" Define tab as 4 spaces
set tabstop=8
set softtabstop=0
set expandtab
set shiftwidth=4
set smarttab

set backspace=indent,eol,start  " Backspace for dummies

set scrolljump=5                " Lines to scroll when cursor leaves screen
set scrolloff=3                 " Minimum lines to keep above and below cursor

set list
set listchars=tab:›\ ,trail:•,extends:#,nbsp:. " Highlight problematic whitespace

" >>>>>>>>>>>>>>>>>>>>>> Formatting <<<<<<<<<<<<<<<<<<<<<<

" Autoindetation when creating new line
filetype indent on
set autoindent
set smartindent
set shiftround

set nospell

" Syntax highlight
filetype plugin on
syntax on

" Speed up vim by caching a lil' bit
set hidden
set history=100

" Remove whitespaces on save
autocmd BufWritePre * :%s/\s\+$//e

" Searching
set incsearch " Start searching when typing
set hlsearch " Highlight search
set ignorecase
set smartcase
set nowrapscan

" >>>>>>>>>>>>>>>>>>>>>> Mappings <<<<<<<<<<<<<<<<<<<<<<

let mapleader = "\<Space>"

nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>n :tabnew<CR>

" Quickly resize windows using +/-
map - <C-W>-
map + <C-W>+
map > <C-W>>
map < <C-W><

" Prevent from using arrow keys
nnoremap <Up> :echomsg "Use k you n00b"<cr>
nnoremap <Down> :echomsg "Use j you n00b"<cr>
nnoremap <Left> :echomsg "Use h you n00b"<cr>
nnoremap <Right> :echomsg "Use l you n00b"<cr>

" Remap esc to jj
ino jj <esc>
cno jj <c-c>
vno v <esc>

" Format the whole document
nnoremap <F3> gg=G

" Window Navigation
" <Leader>hljk = Move between windows
nnoremap <Leader>h <C-w>h
nnoremap <Leader>l <C-w>l
nnoremap <Leader>j <C-w>j
nnoremap <Leader>k <C-w>k

" Window opening
nnoremap <Leader>v <C-w>v
nnoremap <Leader>s <C-w>s

" ============================================================
" |                                                          |
" |                    VIM-base-conf END                     |
" |                                                          |
" ============================================================

" ============================================================
" |                                                          |
" |                   Plugin-specific-conf                   |
" |                                                          |
" ============================================================


" >>>>>>>>>>>>>>>>>>>>>> NERDTREE  <<<<<<<<<<<<<<<<<<<<<<

" Toggle NERDtree with ctrl +t
noremap m :NERDTreeToggle<CR>

" Activate node with key l
let NERDTreeMapActivateNode='l'
let NERDTreeMapCloseChildren='h'

" Auto delete buffer
let NERDTreeAutoDeleteBuffer = 1

" Close NERDtree if it is the only remaining window
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Autoclose NERDTREE on file opening
let NERDTreeQuitOnOpen=1

" Hides "Press ? for help"
let NERDTreeMinimalUI=1

" >>>>>>>>>>>>>>>>>>>>>> LIGHTLINE  <<<<<<<<<<<<<<<<<<<<<<

" Bugfix
set laststatus=2

" Components setup
let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ 'mode_map': { 'c': 'NORMAL' },
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ], [ 'fugitive', 'filename' ] ],
      \   'right': [ ['syntastic', 'lineinfo'], ['percent'], ['fileformat', 'fileencoding', 'filetype']  ]
      \ },
      \ 'component_function': {
      \   'modified': 'LightlineModified',
      \   'readonly': 'LightlineReadonly',
      \   'fugitive': 'LightlineFugitive',
      \   'filename': 'LightlineFilename',
      \   'fileformat': 'LightlineFileformat',
      \   'filetype': 'LightlineFiletype',
      \   'fileencoding': 'LightlineFileencoding',
      \   'mode': 'LightlineMode',
      \ },
      \ 'component_expand': {
      \   'syntastic': 'SyntasticStatuslineFlag',
      \ },
      \ 'component_type': {
      \   'syntastic': 'error',
      \ },
      \ 'separator': { 'left': '', 'right': '' },
      \ 'subseparator': { 'left': '', 'right': '' }
      \ }

function! LightlineModified()
	return &ft =~ 'help\|vimfiler\|gundo' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction

function! LightlineReadonly()
	return &ft !~? 'help\|vimfiler\|gundo' && &readonly ? '' : ''
endfunction

function! LightlineFilename()
	return ('' != LightlineReadonly() ? LightlineReadonly() . ' ' : '') .
		\ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
		\  &ft == 'unite' ? unite#get_status_string() :
		\  &ft == 'vimshell' ? vimshell#get_status_string() :
		\ '' != expand('%:t') ? expand('%:t') : '[No Name]') .
		\ ('' != LightlineModified() ? ' ' . LightlineModified() : '')
endfunction

function! LightlineFugitive()
	if &ft !~? 'vimfiler\|gundo' && exists("*fugitive#head")
		let branch = fugitive#head()
		return branch !=# '' ? ''.branch : ''
	endif
	return ''
endfunction

function! LightlineFileformat()
	return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! LightlineFiletype()
	return winwidth(0) > 70 ? (&filetype !=# '' ? &filetype : 'no ft') : ''
endfunction

function! LightlineFileencoding()
	return winwidth(0) > 70 ? (&fenc !=# '' ? &fenc : &enc) : ''
endfunction

function! LightlineMode()
	return winwidth(0) > 60 ? lightline#mode() : ''
endfunction

augroup AutoSyntastic
    autocmd!
    autocmd BufWritePost *.c,*.cpp call s:syntastic()
augroup END
function! s:syntastic()
    SyntasticCheck
    call lightline#update()
endfunction


" Let the lightline tell me which mod i am currently in
set noshowmode

" >>>>>>>>>>>>>>>>>>>>>> EasyMotion <<<<<<<<<<<<<<<<<<<<<<

" Disable default key-mappings
let g:EasyMotion_do_mapping = 0

" Jump to anywhere you want with minimal keystrokes, with just one key
" binding.
" " `s{char}{label}`
" noremap , <Plug>(easymotion-overwin-f)

" `s{char}{char}{label}`
" " Need one more keystroke, but on average, it may be more comfortable.
nmap , <Plug>(easymotion-overwin-f2)

" Turn on case insensitive feature
let g:EasyMotion_smartcase = 1

" JK motions: Line motions
" map <Leader>j <Plug>(easymotion-j)
" map <Leader>k <Plug>(easymotion-k)


" >>>>>>>>>>>>>>>>>>>>>> Lexima.vim <<<<<<<<<<<<<<<<<<<<<<

let g:lexima_enable_basic_rules = 1

" >>>>>>>>>>>>>>>>>>>>>> Indentline <<<<<<<<<<<<<<<<<<<<<<

let g:indentLine_char = '┆'
let g:indentLine_color_term = 239

" >>>>>>>>>>>>>>>>>>>>>> Ctags <<<<<<<<<<<<<<<<<<<<<<

set tags=./.vimtags;,.vimtags;

" >>>>>>>>>>>>>>>>>>>>>> vim-easytags <<<<<<<<<<<<<<<<<<<<<<

let g:easytags_dynamic_files = 1

" Update tags in background and don't interrupt the foreground processes
let g:easytags_async = 1

" >>>>>>>>>>>>>>>>>>>>>> CTRL-P <<<<<<<<<<<<<<<<<<<<<<

nnoremap <Leader>p :CtrlP<CR>

" >>>>>>>>>>>>>>>>>>>>>> YouCompleteMe  <<<<<<<<<<<<<<<<<<<<<<

" enable completion from tags
let g:ycm_collect_identifiers_from_tags_files = 1

" ============================================================
" |                                                          |
" |               Plugin-specific-conf END                   |
" |                                                          |
" ============================================================
