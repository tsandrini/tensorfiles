let g:lsp_diagnostics_echo_cursor = 1 " enable echo under cursor when in normal mode

let g:lsp_signs_error = {'text': '✗'}
let g:lsp_signs_warning = {'text': '‼'} "

set completeopt+=preview
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

nnoremap <Leader>= :LspDocumentFormat<CR>
nnoremap <Leader>bd :LspDefinition<CR>
nnoremap <Leader>bc :LspDocumentDiagnostics<CR>
nnoremap <Leader>br :LspReferences<CR>
