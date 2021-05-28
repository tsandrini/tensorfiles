"vim: set ts=8 sw=4 tw=78 et :

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
