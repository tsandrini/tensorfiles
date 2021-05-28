" vim: set ts=8 sw=4 tw=78 et :

" >>>>>>>>>>>>>>>>>>>>>> Augroups <<<<<<<<<<<<<<<<<<<<<<

" Reload vimrc if it's being edited
augroup myvimrc
    au!
    au BufWritePost .vimrc,_vimrc,vimrc,.gvimrc,_gvimrc,gvimrc so $MYVIMRC | if has('gui_running') | so $MYGVIMRC | endif
augroup END

au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif " Return to the last position when opening files

autocmd BufWritePre * :%s/\s\+$//e " Removes unnecessary whitespaces on save
