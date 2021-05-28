"vim: set ts=8 sw=4 tw=78 et :

" >>>>>>>>>>>>>>>>>>>>>> Ale <<<<<<<<<<<<<<<<<<<<<<

let g:ale_sign_error = '✗'
let g:ale_sign_warning = '∆'

nmap <Leader>e <Plug>(ale_previous_wrap) " Jump quickly through errors
nmap <Leader>E <Plug>(ale_next_wrap) " Jump quickly through errors
