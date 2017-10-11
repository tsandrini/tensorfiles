"vim: set ts=8 sw=4 tw=78 et :

" >>>>>>>>>>>>>>>>>>>>>> General <<<<<<<<<<<<<<<<<<<<<<

" Modelines
set modeline
set modelines=5

set autoread " Refresh file contents if modified

" PERFORMANCE
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
set backup
set noswapfile

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
set clipboard=unnamedplus " Set default register to system clipboard
