"vim: set ts=8 sw=4 tw=78 et :

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

" Define tab as 4 spaces
set tabstop=8
set softtabstop=0
set expandtab
set shiftwidth=4
set smarttab

set scrolloff=5 " Minimum lines to keep above and below cursor

set list
set listchars=tab:›\ ,trail:•,extends:#,nbsp:. " Highlight problematic whitespace
