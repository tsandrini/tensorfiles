" Security
set secure

" Prevent from reccuring itself
set noexrc

" ============================================================
" |                                                          |
" |                      PlugImport                          |
" |                                                          |
" ============================================================

call plug#begin('~/.vim/plugged')

	" PHPCD (goto definition + completions)
	Plug 'php-vim/phpcd.vim', { 'for': 'php' , 'do': 'composer update' }

	" NERDtree (sidebar panel)
	Plug 'scrooloose/nerdtree'

	" NERDtree-git (Show git differences in NERDtree)
	Plug 'Xuyuanp/nerdtree-git-plugin'

	" Supertab (Autocompletion via tabulator)
	Plug 'ervandew/supertab'

	" Lightline (simplified vesrion of powerline)
	Plug 'itchyny/lightline.vim'

	" Vim-fugitive (git interaction)
	Plug 'tpope/vim-fugitive'

	" PHP-vim
	Plug 'stanangeloff/php.vim'

	" PHP tools (Codesniffer, mess detector, syntax errors)
	" Plug 'joonty/vim-phpqa'

	" Syntastic (syntax cheking tools)
	Plug 'scrooloose/syntastic'

	" EasyMotion
	Plug 'easymotion/vim-easymotion'

	" Vim-twig (syntax, snippets etc.)
	Plug 'evidens/vim-twig'

	" Surround.vim (parenthesis used as object)
	Plug 'tpope/vim-surround'

	" Lexima.vim (auto-complete parenthesis)
	Plug 'cohama/lexima.vim'

        " Phpcomplete
        Plug 'shawncplus/phpcomplete.vim'

        " vim-startify
        Plug 'mhinz/vim-startify'

        " indentline (Show indent lines)
        Plug 'yggdroot/indentline'

        " Ctrl-P (currently best fuzzy finder)
        Plug 'ctrlpvim/ctrlp.vim'
        
        " vim-php-namespace (types use statements)
        Plug 'arnaud-lb/vim-php-namespace'
        
        " vim-php
        Plug 'vim-php/tagbar-phpctags.vim'
       
        " Tagbar
        Plug 'majutsushi/tagbar'

        " vim-easytags (needed for Tagbar)
        Plug 'xolox/vim-easytags'

        " vim-misc (needed for vim-easytags)
        Plug 'xolox/vim-misc'
        
        " vim-devicons 
        Plug 'ryanoasis/vim-devicons'

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

" Wildmode
set wildmode=full
set wildmenu
set wildignorecase

" Define tab as 4 spaces
set tabstop=8
set softtabstop=0
set expandtab
set shiftwidth=4
set smarttab

" Command line history
set history=100

" Cache rendering
set lazyredraw
set ttyfast


" Where to put *.swp files
set dir=~/.vim/tmp

" Where to put backup files
set backupdir=~/.vim/backupdir

" Set default clipboard
set clipboard=unnamed

" Autoindetation when creating new line
filetype indent on
set autoindent
set smartindent
set shiftround

" Wrapping
set wrap
set showmatch
set linebreak
set nofoldenable

" UI
set ruler

" Activate relative numbering in sidebar
set relativenumber
" Show absolute number on current line
set number

" Remap esc to jj
ino jj <esc>
cno jj <c-c>
vno v <esc>

" Syntax highlight
filetype plugin on
syntax on

" Set manually file syntax
"au BufReadPost *.twig set syntax=html
"au BufReadPost *.tpl set syntax=html

" Set encoding
scriptencoding utf-8
set encoding=utf-8                                  
set termencoding=utf-8
set fileencodings=ucs-bom,utf-8,gbk,big5,latin1

" Spell checking
setlocal spell spelllang=cs
"set spell

" Quickly resize windows use +/-
map - <C-W>-
map + <C-W>+
map > <C-W>>
map < <C-W><

" Prevent from using arrow keys
nnoremap <Up> :echomsg "Use k you n00b"<cr>
nnoremap <Down> :echomsg "Use j you n00b"<cr>
nnoremap <Left> :echomsg "Use h you n00b"<cr>
nnoremap <Right> :echomsg "Use l you n00b"<cr>

" new tab
map <C-x>n :tabnew<CR>
" close tab
map <C-x>c :tabclose<CR> 

"set lines=35 columns=150

" Speed up vim by caching a lil' bit
set hidden
set history=100

" Remove whitespaces on save
autocmd BufWritePre * :%s/\s\+$//e

" Searching
set hlsearch
set ignorecase
set smartcase
set nowrapscan


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
nmap <C-t> :NERDTreeToggle<CR>

" Activate node with key l
let NERDTreeMapActivateNode='l'
let NERDTreeMapCloseChildren='h'

" Auto delete buffer
let NERDTreeAutoDeleteBuffer = 1


" >>>>>>>>>>>>>>>>>>>>>> LIGHTLINE  <<<<<<<<<<<<<<<<<<<<<<

" Bugfix
set laststatus=2

" Components setup
let g:lightline = {
      \ 'colorscheme': 'landscape',
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

" >>>>>>>>>>>>>>>>>>>>>> PHP-VIM  <<<<<<<<<<<<<<<<<<<<<<

function! PhpSyntaxOverride()
	hi! def link phpDocTags  phpDefine
	hi! def link phpDocParam phpType
endfunction

augroup phpSyntaxOverride
	autocmd!
	autocmd FileType php call PhpSyntaxOverride()
augroup END

" >>>>>>>>>>>>>>>>>>>>>> EasyMotion <<<<<<<<<<<<<<<<<<<<<<

" Disable default key-mappings
let g:EasyMotion_do_mapping = 0

" Jump to anywhere you want with minimal keystrokes, with just one key
" binding.
" " `s{char}{label}`
nmap <Space> <Plug>(easymotion-overwin-f)

" `s{char}{char}{label}`
" " Need one more keystroke, but on average, it may be more comfortable.
nmap <Space> <Plug>(easymotion-overwin-f2)

" Turn on case insensitive feature
let g:EasyMotion_smartcase = 1

" JK motions: Line motions
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)


" >>>>>>>>>>>>>>>>>>>>>> Lexima.vim <<<<<<<<<<<<<<<<<<<<<<

let g:lexima_enable_basic_rules = 1

" >>>>>>>>>>>>>>>>>>>>>> Syntastic <<<<<<<<<<<<<<<<<<<<<<
"
let g:syntastic_always_populate_loc_list = 2
let g:syntastic_auto_loc_list = 2
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_enable_balloons = 0
let g:syntastic_loc_list_height = 5
let g:syntastic_ignore_files = ['\.min\.js$', '\.min\.css$', '\.sw?', '.env*']

let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '✗'
let g:syntastic_style_error_symbol = '∆'
let g:syntastic_style_warning_symbol = '∆'

" >>>>>>>>>>>>>>>>>>>>>> Indentline <<<<<<<<<<<<<<<<<<<<<<

let g:indentLine_char = '┆'
let g:indentLine_color_term = 239

" >>>>>>>>>>>>>>>>>>>>>> Ctags <<<<<<<<<<<<<<<<<<<<<<

set tags=./.vimtags;,.vimtags;

" >>>>>>>>>>>>>>>>>>>>>> PHP-cs-fixer <<<<<<<<<<<<<<<<<<<<<<

nnoremap <silent><leader>pcd :call PhpCsFixerFixDirectory()<CR>
nnoremap <silent><leader>pcf :call PhpCsFixerFixFile()<CR>

" >>>>>>>>>>>>>>>>>>>>>> vim-easytags <<<<<<<<<<<<<<<<<<<<<<

let g:easytags_dynamic_files = 1

" >>>>>>>>>>>>>>>>>>>>>> Tagbar <<<<<<<<<<<<<<<<<<<<<<

noremap <F2> :TagbarToggle<CR>

" ============================================================
" |                                                          |
" |               Plugin-specific-conf END                   |
" |                                                          |
" ============================================================
