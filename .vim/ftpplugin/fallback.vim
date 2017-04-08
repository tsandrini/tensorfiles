" Security
set secure

" Read local .vimrc
set exrc

" ============================================================
" | 			                                     |
" |		         PlugImport                          |
" |                                                          |
" ============================================================

call plug#begin('~/.vim/plugged')
	
	" NERDtree (sidebar panel)
	Plug 'scrooloose/nerdtree'  

	" NERDtree-git (Show git differences in NERDtree) 
	Plug 'Xuyuanp/nerdtree-git-plugin'  
	
	" Supertab (Autocompleion via tabulator)
	Plug 'ervandew/supertab'

	" Lightline (simplified vesrion of powerline)
	Plug 'itchyny/lightline.vim'
	
	" Vim-fugitive (git interaction)
	Plug 'tpope/vim-fugitive'  

	" Command-t (fast file navigation)
	Plug 'wincent/command-t'

	" EasyMotion
	Plug 'easymotion/vim-easymotion'

        " Ctrl-P (currently best fuzzy finder)
        Plug 'ctrlpvim/ctrlp.vim'

         " Lexima.vim (auto-complete parenthesis)
        Plug 'cohama/lexima.vim'

        " vim-devicons
        Plug 'ryanoasis/vim-devicons'

 				  
call plug#end()

" ============================================================
" | 			                                     |
" |			 PlugImport END                      |
" |                                                          |
" ============================================================

" ============================================================
" | 				        		     |
" |		 VIM-base-configuration                      |
" |                                                          |
" ============================================================

" Activate tab-autocompleteion in : mode
set wildmode=full

" Define tab as 4 spaces
set tabstop=8
set softtabstop=0
set expandtab
set shiftwidth=4
set smarttab

" Command line history
set history=100

" Where to put *.swp files
set dir=~/.vim/tmp

" Where to put backup files
set backupdir=~/.vim/backup

" Wrap long lines to multiple lines
set wrap

" Set default clipboard
set clipboard=unnamed

" Autoindetation when creating new line
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

" Set encoding
scriptencoding utf-8
set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,gbk,big5,latin1

" Spell checking
" setlocal spell spelllang=cs
" set spell

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

" Toggle NERDtree with ctrl + t
nmap <C-t> :NERDTreeToggle<CR> 

let NERDTreeMapActivateNode='l' 
let NERDTreeMapCloseChildren='h'

" Lightline

" >>>>>>>>>>>>>>>>>>>>>> LIGHTLINE  <<<<<<<<<<<<<<<<<<<<<<

" Bugfix
set laststatus=2

" Compoments setup
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

" Let zhe lightline tell me which mod a amm currently in 
set noshowmode

" >>>>>>>>>>>>>>>>>>>>>> EasyMotion <<<<<<<<<<<<<<<<<<<<<<

" Disable default key-mappings
let g:EasyMotion_do_mapping = 0

" Jump to anywhere you want with minimal keystrokes, with just one key
" binding.
" `s{char}{label}`
nmap <Space> <Plug>(easymotion-overwin-f)

" `s{char}{char}{label}`
" Need one more keystroke, but on average, it may be more comfortable.
nmap <Space> <Plug>(easymotion-overwin-f2)

" Turn on case insensitive feature
let g:EasyMotion_smartcase = 1

" JK motions: Line motions
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)


" >>>>>>>>>>>>>>>>>>>>>> Ctags <<<<<<<<<<<<<<<<<<<<<<

set tags=./.vimtags;,.vimtags;

" ============================================================
" | 			                                     |
" |	          Plugin-specific-conf END                   |
" |                                                          |
" ============================================================
