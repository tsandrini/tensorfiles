set nocompatible " This has to be the first thing
set secure " Shell commands not avaible in .vimrc
set exrc " Vim can load local .vimrc

" ============================================================
" |                                                          |
" |                      PlugImport                          |
" |                                                          |
" ============================================================

call plug#begin('~/.vim/plugged')

" BASE STUFF

Plug 'scrooloose/nerdtree' " NERDtree | must have
Plug 'easymotion/vim-easymotion' " Easymotion | jump everywhere in document
Plug 'ctrlpvim/ctrlp.vim' " CtrlP | Really comfort-ish fuzzy finder
Plug 'ryanoasis/vim-devicons' " Devicons | Pretty icons, 'cause I need them
Plug 'yggdroot/indentline' " Indentline | Show indentlines
Plug 'itchyny/lightline.vim' " Lightline | Cause Powerline > Lightline
Plug 'tpope/vim-surround' " Surround | Parenthesis used as text object
Plug 'cohama/lexima.vim' " Auto-complete parenthesis
Plug 'mhinz/vim-startify' " Startify | pretty starting CReature with usefull quotes :)
Plug 'scrooloose/nerdcommenter' " NERDcommenter | feels good to comment stuff
Plug 'skammer/vim-css-color' " Idk - i guess some kind of colors
Plug 'sjl/gundo.vim' " Gundo | smarter fork of vim undo
Plug 'jlanzarotta/bufexplorer'

" EXUBERANT TAGS (tags integration)

Plug 'xolox/vim-easytags' " Easytags | interactions with exuberant tags
Plug 'xolox/vim-misc' " Misc | idk, easytags needs it

" SYNTAX

Plug 'PotatoesMaster/i3-vim-syntax' " i3 syntax
Plug 'elzr/vim-json' " vim-json | base vim support for json is awful
Plug 'kchmck/vim-coffee-script' " Coffeescript support

" LANGUAGE SPECIFIC

Plug 'davidhalter/jedi-vim' " jedi-vim
Plug 'elzr/vim-json' " vim-sjon | base vim support for json is awful
Plug 'w0rp/ale'

" GIT INTERACTIONS
Plug 'gisphm/vim-gitignore' " Gitignore | ignore 'em !
Plug 'Xuyuanp/nerdtree-git-plugin' " NERDtree-git | git interactions to NERDtree
Plug 'tpope/vim-fugitive' " Fugitive | Git interactions
" Plug 'mmozuras/vim-github-comment'

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

" Modelines
set modeline
set modelines=5

set autoread " Refresh file contents if modified

" PERFORMANCE
set nomodeline " Just to be sure
set nospell " Spell checking, Never got it to work properly
set nocursorcolumn " Draws currently active column -> super slow
set nocursorline " Draws currently active line -> super slow
set lazyredraw " Buffer sCReen updates
set ttyfast " Fast terminal connection
set history=100 " History
set hidden " Avoid keeping closed buffers in background

" Temporary, Backup files
set dir=~/.vim/tmp " Where to store *.sw? files
set backupdir=~/.vim/backup " Where to store backup files
set nobackup
set swapfile

" Enabled undofiles
set undodir=~/.vim/undos
set undolevels=300
set undoreload=300
set undofile

" FILE ENCODING
scriptencoding utf-8
set encoding=utf-8
set termencoding=utf-8
set fileencodings=ucs-bom,utf-8,gbk,big5,latin1

" >>>>>>>>>>>>>>>>>>>>>> GUI stuff <<<<<<<<<<<<<<<<<<<<<<

set background=dark
colorscheme delek

set wrap " Enable wrapping
set linebreak " Don't insert <EOL> at the end of the visible line
set textwidth=0
set wrapmargin=0
set formatoptions+=l

set ruler " Enable ruler
set rulerformat=%l\:%c " Set ruler format

set nofoldenable " Prevent from folding
set noshowmode " Don't need this with lightline

set number " Show line numbers
set relativenumber " Show relative numbers insetad of the absolute ones

set wildmenu " Enable wildmenu
set wildmode=full " Wildmode - don't show all results, just cycle through them
set wildignorecase " Ignore case in wildmenu

set clipboard=unnamedplus " Set default register to system clipboard

" Define tab as 4 spaces
set tabstop=8
set softtabstop=0
set expandtab
set shiftwidth=4
set smarttab

set scrolloff=5 " Minimum lines to keep above and below cursor

set list
set listchars=tab:›\ ,trail:•,extends:#,nbsp:. " Highlight problematic whitespace

au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif " Return to the last position when opening files

" >>>>>>>>>>>>>>>>>>>>>> Highlights <<<<<<<<<<<<<<<<<<<<<<

highlight SpellBad term=reverse ctermbg=12 gui=undercurl guisp=Blue
highlight Error term=reverse ctermfg=16 ctermbg=3 guifg=White guibg=Red

" >>>>>>>>>>>>>>>>>>>>>> Searching <<<<<<<<<<<<<<<<<<<<<<

filetype plugin on " Enable ftp plugin
syntax on " Enable file-specific syntax highlight

filetype indent on " File specific indentation
set autoindent " Automatic indent when CReating new line
set smartindent " smart autoindent 8)
set shiftround

set incsearch " Start searching when typing
set hlsearch " Highlight search
set smartcase " Ignore case only when lowercase
set nowrapscan " Searches wrap around the end of the file
set showmatch " Highlight the matching bracket
set wrapscan " Why haven't I set this earlier ....

" >>>>>>>>>>>>>>>>>>>>>> Text-formatting <<<<<<<<<<<<<<<<<<<<<<

autocmd BufWritePre * :%s/\s\+$//e " Removes unnecessary whitespaces on save

" >>>>>>>>>>>>>>>>>>>>>> Functions <<<<<<<<<<<<<<<<<<<<<<

function! AppendModeline()
    let l:modeline = printf("vim: set ts=%d sw=%d tw=%d %set :",
        \ &tabstop, &shiftwidth, &textwidth, &expandtab ? '' : 'no')
    let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
    call append(0, l:modeline)
endfunction

" >>>>>>>>>>>>>>>>>>>>>> Mappings <<<<<<<<<<<<<<<<<<<<<<

let mapleader = "\<Space>" " remap leader

set backspace=indent,eol,start " Backspace for dummies

nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>Q :qall<CR>
nnoremap <Leader>x :x<CR>
nnoremap <Leader>X :xall<CR>
nnoremap <Leader>n :tabnew<CR>

nnoremap <Leader>f :noh<CR>

nnoremap J :tabprevious<CR>
nnoremap K :tabnext<CR>

" Quickly resize windows using +/-
map - <C-W>-
map + <C-W>+
map > <C-W>>
map < <C-W><

" Prevent from using arrow keys
nnoremap <Up> :echomsg "Use k you n00b"<CR>
nnoremap <Down> :echomsg "Use j you n00b"<CR>
nnoremap <Left> :echomsg "Use h you n00b"<CR>
nnoremap <Right> :echomsg "Use l you n00b"<CR>

" Remap esc to jj
ino jk <esc>
ino kj <esc>
cno jk <c-c>
cno kj <c-c>
vno v <esc>

" Format the whole document
nnoremap <Leader>= mzgg=G'z

" Window Navigation
" <Leader>hljk = Move between windows
nnoremap <Leader>h <C-w>h
nnoremap <Leader>l <C-w>l
nnoremap <Leader>j <C-w>j
nnoremap <Leader>k <C-w>k

" Window opening
nnoremap <Leader>v <C-w>v
nnoremap <Leader>s <C-w>s

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! %!sudo tee > /dev/null %

nnoremap <silent> <Leader>ml :call AppendModeline()<CR>

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

noremap m :NERDTreeToggle<CR>
noremap <Leader>m :NERDTreeFind<CR>

let NERDTreeMapActivateNode='l' " Toggle child nodes with l
let NERDTreeMapCloseChildren='h' " Close  child nodes with h

let NERDTreeQuitOnOpen=1 " Autoclose NERDTREE on file opening
let NERDTreeMinimalUI=1 " Hides 'Press ? for help'
let NERDTreeAutoDeleteBuffer = 1 " Auto delete buffer
let g:NERDTreeWinSize=35

autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif " Close NERDtree if only remaining window

" >>>>>>>>>>>>>>>>>>>>>> LIGHTLINE  <<<<<<<<<<<<<<<<<<<<<<

set laststatus=2 " Bugfix

" Components setup
let g:lightline = {
            \ 'colorscheme': 'wombat',
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

" >>>>>>>>>>>>>>>>>>>>>> EasyMotion <<<<<<<<<<<<<<<<<<<<<<

let g:EasyMotion_do_mapping = 0 " Disable default key-mappings
let g:EasyMotion_smartcase = 1 " Turn on case insensitive feature

" `s{char}{char}{label}`
" " Need one more keystroke, but on average, it may be more comfortable.
nmap , <Plug>(easymotion-overwin-f2)

" >>>>>>>>>>>>>>>>>>>>>> Lexima.vim <<<<<<<<<<<<<<<<<<<<<<

let g:lexima_enable_basic_rules = 1
let g:lexima_enable_newline_rules = 1
let g:lexima_enable_endwise_rules = 1

" >>>>>>>>>>>>>>>>>>>>>> Indentline <<<<<<<<<<<<<<<<<<<<<<

let g:indentLine_char = '┆'
let g:indentLine_color_term = 239

" >>>>>>>>>>>>>>>>>>>>>> Ctags <<<<<<<<<<<<<<<<<<<<<<

set tags=./.vimtags;,.vimtags;
let g:easytags_file = '.vimtags'

" >>>>>>>>>>>>>>>>>>>>>> vim-easytags <<<<<<<<<<<<<<<<<<<<<<

let g:easytags_dynamic_files = 1

let g:easytags_async = 1 " Update tags in background and don't interrupt the foreground processes

" >>>>>>>>>>>>>>>>>>>>>> CTRL-P <<<<<<<<<<<<<<<<<<<<<<

let g:ctrlp_map = '<Leader>p' " Chage default keybinding

" >>>>>>>>>>>>>>>>>>>>>> Gundo <<<<<<<<<<<<<<<<<<<<<<

nnoremap <Leader>g :GundoToggle<CR>

" >>>>>>>>>>>>>>>>>>>>>> Ale <<<<<<<<<<<<<<<<<<<<<<

let g:ale_sign_error = '✗'
let g:ale_sign_warning = '∆'

nmap <Leader>e <Plug>(ale_previous_wrap) " Jump quickly through errors
nmap <silent>E <Plug>(ale_next_wrap) " Jump quickly through errors

" ============================================================
" |                                                          |
" |               Plugin-specific-conf END                   |
" |                                                          |
" ============================================================
