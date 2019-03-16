"vim: set ts=8 sw=4 tw=78 et :

set nocompatible " This has to be the first thing
set secure " Shell commands not avaible in .vimrc
set exrc " Prevent from reccuring itself

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
Plug 'tpope/vim-surround' " Surround | Parenthesis used as text object
Plug 'cohama/lexima.vim' " Auto-complete parenthesis
Plug 'mhinz/vim-startify' " Startify | pretty starting CReature with usefull quotes :)
Plug 'scrooloose/nerdcommenter' " NERDcommenter | feels good to comment stuff
Plug 'sjl/gundo.vim' " Gundo | smarter fork of vim undo
Plug 'jlanzarotta/bufexplorer'


" GIT INTERACTIONS
Plug 'gisphm/vim-gitignore' " Gitignore | ignore 'em !
Plug 'Xuyuanp/nerdtree-git-plugin' " NERDtree-git | git interactions to NERDtree

" LANGUAGE SPECIFIC
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'vim-pandoc/vim-pandoc'


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



source ~/.vim/config/parts/plugins/easymotion.vim


source ~/.vim/config/parts/plugins/lexima.vim


source ~/.vim/config/parts/plugins/indentline.vim


source ~/.vim/config/parts/plugins/ctrlp.vim


source ~/.vim/config/parts/plugins/gundo.vim


" ============================================================
" |                                                          |
" |               Plugin-specific-conf END                   |
" |                                                          |
" ============================================================
