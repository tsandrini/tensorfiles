au User lsp_setup call lsp#register_server({
            \ 'name': 'php-language-server',
            \ 'cmd': {server_info->['php', expand('~/.vim/plugged/php-language-server/bin/php-language-server.php')]},
            \ 'whitelist': ['php'],
            \ })
