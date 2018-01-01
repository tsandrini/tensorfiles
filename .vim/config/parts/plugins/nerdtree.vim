"vim: set ts=8 sw=4 tw=78 et :

" >>>>>>>>>>>>>>>>>>>>>> NERDTREE  <<<<<<<<<<<<<<<<<<<<<<

nnoremap m :NERDTreeToggle<CR>
nnoremap <Leader>m :NERDTreeFind<CR>

let NERDTreeMapActivateNode='l' " Toggle child nodes with l
let NERDTreeMapCloseChildren='h' " Close  child nodes with h

let NERDTreeQuitOnOpen=1 " Autoclose NERDTREE on file opening
let NERDTreeMinimalUI=1 " Hides 'Press ? for help'
let NERDTreeAutoDeleteBuffer = 1 " Auto delete buffer
let g:NERDTreeWinSize=35

autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif " Close NERDtree if only remaining window
