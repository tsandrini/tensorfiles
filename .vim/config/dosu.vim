set nocompatible " This has to be the first thing
set secure " Shell commands not avaible in .vimrc
set noexrc " Prevent from reccuring itself

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
Plug 'sjl/gundo.vim' " Gundo | smarter fork of vim undo
Plug 'jlanzarotta/bufexplorer'

" EXUBERANT TAGS (tags integration)

Plug 'xolox/vim-easytags' " Easytags | interactions with exuberant tags
Plug 'xolox/vim-misc' " Misc | idk, easytags needs it

" SYNTAX

Plug 'vim-pandoc/vim-pandoc-syntax'

" LANGUAGE SPECIFIC

Plug 'vim-pandoc/vim-pandoc'

" GIT INTERACTIONS
Plug 'gisphm/vim-gitignore' " Gitignore | ignore 'em !
Plug 'Xuyuanp/nerdtree-git-plugin' " NERDtree-git | git interactions to NERDtree

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


source ~/.vim/config/parts/general.vim


source ~/.vim/config/parts/autocommands.vim


source ~/.vim/config/parts/gui.vim


source ~/.vim/config/parts/highlights.vim


source ~/.vim/config/parts/searching.vim


source ~/.vim/config/parts/functions.vim


source ~/.vim/config/parts/mappings.vim


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


source ~/.vim/config/parts/plugins/nerdtree.vim



"vim: set ts=8 sw=4 tw=78 et :

" >>>>>>>>>>>>>>>>>>>>>> LIGHTLINE  <<<<<<<<<<<<<<<<<<<<<<

set laststatus=2 " Bugfix

" Components setup
let g:lightline = {
            \ 'colorscheme': 'wombat',
            \ 'mode_map': { 'c': 'NORMAL' },
            \ 'active': {
            \   'left': [ [ 'mode', 'paste' ], [ 'fugitive', 'filename' ] ],
            \   'right': [ ['lineinfo'], ['percent'], ['fileformat', 'fileencoding', 'filetype']  ]
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
            \ },
            \ 'component_type': {
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

source ~/.vim/config/parts/plugins/easymotion.vim


source ~/.vim/config/parts/plugins/lexima.vim


source ~/.vim/config/parts/plugins/indentline.vim


source ~/.vim/config/parts/plugins/ctags.vim


source ~/.vim/config/parts/plugins/easytags.vim


source ~/.vim/config/parts/plugins/ctrlp.vim


source ~/.vim/config/parts/plugins/gundo.vim


source ~/.vim/config/parts/plugins/pandoc.vim


" ============================================================
" |                                                          |
" |               Plugin-specific-conf END                   |
" |                                                          |
" ============================================================
