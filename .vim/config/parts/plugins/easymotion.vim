"vim: set ts=8 sw=4 tw=78 et :

" >>>>>>>>>>>>>>>>>>>>>> EasyMotion <<<<<<<<<<<<<<<<<<<<<<

let g:EasyMotion_do_mapping = 0 " Disable default key-mappings
let g:EasyMotion_smartcase = 1 " Turn on case insensitive feature

" `s{char}{char}{label}`
" " Need one more keystroke, but on average, it may be more comfortable.
nmap , <Plug>(easymotion-overwin-f2)
