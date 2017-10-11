"vim: set ts=8 sw=4 tw=78 et :

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
nnoremap <Leader>r :so $MYVIMRC<CR>

nnoremap J :tabprevious<CR>
nnoremap K :tabnext<CR>

" Quickly resize windows using +/-
"map - <C-W>-
"map + <C-W>+
"map > <C-W>>
"map < <C-W><

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

" Append base modelines
nnoremap <silent> <Leader>ml :call AppendModeline()<CR>
