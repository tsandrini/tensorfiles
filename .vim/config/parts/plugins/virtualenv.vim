"vim: set ts=8 sw=4 tw=78 et :

" >>>>>>>>>>>>>>>>>>>>>> Virtualenv <<<<<<<<<<<<<<<<<<<<<<


let g:virtualenv_directory = '~/.envs'
let g:virtualenv_auto_activate = 1

au VimEnter * if exists('*virtualenv#activate') | call virtualenv#activate('vim') | endif
