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
	Plug 'joonty/vim-phpqa'

	" EasyMotion
	Plug 'easymotion/vim-easymotion'
	
	" Vim-twig (syntax, snippets etc.)
	Plug 'evidens/vim-twig'
		
	" Command-t (fast-file navigation)
	Plug 'wincent/command-t'

	" Surround.vim (autocomplete parenthesis)
	Plug 'tpope/vim-surround'

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

" Activate tab-autocompleteion in : mode
set wildmode=full

" Set tab-width
set shiftwidth=4
set tabstop=4
set softtabstop=0 noexpandtab

" Wrap long lines on multiple lines
set wrap

" Set default clipboard
set clipboard=unnamedplus

" Autoindetation when creating new line
filetype indent on
set autoindent
set smartindent

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
set encoding=utf-8
scriptencoding utf-8

" Spell checking
setlocal spell spelllang=cs
"set spell

" Prevent from using arrow keys
nnoremap <Up> :echomsg "Use k you n00b"<cr>
nnoremap <Down> :echomsg "Use j you n00b"<cr>
nnoremap <Left> :echomsg "Use h you n00b"<cr>
nnoremap <Right> :echomsg "Use l you n00b"<cr>

"set lines=35 columns=150

" Speed up vim by caching a lil' bit
set hidden
set history=100

" Remove whitespaces on save
autocmd BufWritePre * :%s/\s\+$//e

" Highlight searched word
set hlsearch


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

" >>>>>>>>>>>>>>>>>>>>>> LIGHTLINE  <<<<<<<<<<<<<<<<<<<<<< 

" Bugfix
set laststatus=2

" Components setup
let g:lightline = {
      \ 'colorscheme': 'landscape',
      \ 'mode_map': { 'c': 'NORMAL' },
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ], [ 'fugitive', 'filename' ] ]
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

" ============================================================
" |                                                          |
" |               Plugin-specific-conf END                   |
" |                                                          |
" ============================================================

