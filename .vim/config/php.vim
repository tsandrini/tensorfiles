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
Plug 'vim-php/tagbar-phpctags.vim' " Tagbar-phpctags | ctags for php

" SYNTAX

Plug 'elzr/vim-json' " vim-json | base vim support for json is awful
Plug 'kchmck/vim-coffee-script' " Coffeescript support

" LANGUAGE SPECIFIC

Plug 'stanangeloff/php.vim' " PHPvim | better base support for php
Plug 'php-vim/phpcd.vim', { 'for': 'php' , 'do': 'composer update' } " PHPcd | goto definition and more
Plug 'lumiliet/vim-twig' " Twig | much better support for twig
Plug 'majutsushi/tagbar' " Tagbar | class preview - super cool dope stuff
Plug 'shawncplus/phpcomplete.vim' " PHPcomplete | improved php-autocompletions
Plug 'Valloric/YouCompleteMe' " Autocompletion
Plug 'w0rp/ale'

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


source ~/.vim/config/parts/plugins/lightline.vim


source ~/.vim/config/parts/plugins/nerdtree.vim


source ~/.vim/config/parts/plugins/php-vim.vim


source ~/.vim/config/parts/plugins/phpcomplete.vim


source ~/.vim/config/parts/plugins/easymotion.vim


source ~/.vim/config/parts/plugins/lexima.vim


source ~/.vim/config/parts/plugins/indentline.vim


source ~/.vim/config/parts/plugins/ctags.vim


source ~/.vim/config/parts/plugins/easytags.vim


source ~/.vim/config/parts/plugins/ctrlp.vim


source ~/.vim/config/parts/plugins/youcompleteme.vim


source ~/.vim/config/parts/plugins/gundo.vim


source ~/.vim/config/parts/plugins/ale.vim


source ~/.vim/config/parts/plugins/json.vim


" ============================================================
" |                                                          |
" |               Plugin-specific-conf END                   |
" |                                                          |
" ============================================================
