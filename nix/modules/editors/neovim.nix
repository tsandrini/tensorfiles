# --- modules/editors/neovim.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
# URL:     https://github.com/tsandrini/tensorfiles
# License: MIT
#
# 888                                                .d888 d8b 888
# 888                                               d88P"  Y8P 888
# 888                                               888        888
# 888888 .d88b.  88888b.  .d8888b   .d88b.  888d888 888888 888 888  .d88b.  .d8888b
# 888   d8P  Y8b 888 "88b 88K      d88""88b 888P"   888    888 888 d8P  Y8b 88K
# 888   88888888 888  888 "Y8888b. 888  888 888     888    888 888 88888888 "Y8888b.
# Y88b. Y8b.     888  888      X88 Y88..88P 888     888    888 888 Y8b.          X88
#  "Y888 "Y8888  888  888  88888P'  "Y88P"  888     888    888 888  "Y8888   88888P'

{ config, options, pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    withNodeJs = true;
    plugins = with pkgs.vimPlugins; [
      vim-repeat
      nvim-web-devicons
      nnn-vim
      vim-fugitive
      {
        plugin = indentLine;
        config = ''
        let g:indentLine_char = '┆'
        let g:indentLine_color_term = 239
        '';
      }
      lexima-vim
      {
        plugin = vim-vsnip;
        config = ''
        '';
      }
      vim-vsnip-integ
      friendly-snippets
      {
        plugin = vim-move;
        config = ''
        let g:move_key_modifier = "C"
        '';
      }
      {
        plugin = fern-vim;
        config = ''
        " Disable netrw
        let g:loaded_netrw = 0
        let g:loaded_netrwPlugin = 0
        let g:loaded_netrwSettings = 0
        let g:loaded_netrwFileHandlers = 0

        " Enable nerdfont
        let g:fern#renderer = "nerdfont"
        let g:fern#disable_default_mappings = 1

        " I only use fern as a drawer opened via `m` and closed either by `q` or by
        " selecting and opening a node
        nnoremap <silent> m :Fern . -drawer -reveal=% -width=35 <CR><C-w>=

        " Setup close action for a further "open and close" mapping
        nnoremap <silent> <Plug>(fern-close-drawer) :<C-u>FernDo close -drawer -stay<CR>

        function! s:init_fern() abort
          " Use 'select' instead of 'edit' for default 'open' action
          nmap <buffer> <Plug>(fern-action-open) <Plug>(fern-action-open:select)
          nmap <buffer> <Plug>(fern-action-custom-open-expand-collapse) <Plug>fern#smart#leaf(<plug>(fern-action-open)<plug>(fern-close-drawer), <plug>(fern-action-expand), <plug>(fern-action-collapse))
          nmap <buffer> q :<C-u>quit<CR>
          nmap <buffer> n <Plug>(fern-action-new-path)
          nmap <buffer> d <Plug>(fern-action-remove)
          nmap <buffer> m <Plug>(fern-action-move)
          nmap <buffer> r <Plug>(fern-action-rename)
          nmap <buffer> R <Plug>(fern-action-reload)
          nmap <buffer> <C-h> <Plug>(fern-action-hidden-toggle)
          nmap <buffer> l <Plug>(fern-action-custom-open-expand-collapse)
          nmap <buffer> h <Plug>(fern-action-collapse)
          nmap <buffer> <2-LeftMouse> <Plug>(fern-action-custom-open-expand-collapse)
          nmap <buffer> <CR> <Plug>(fern-action-custom-open-expand-collapse)
        endfunction

        augroup fern-custom
          autocmd! *
          autocmd FileType fern call s:init_fern()
        augroup END
        '';
      }
      popup-nvim
      plenary-nvim
      {
        plugin = telescope-nvim;
        config = ''
        require('telescope').setup{
          defaults = {
            prompt_prefix = "🔍"
          }
        }
        '';
      }
      {
        plugin = vim-easymotion;
        config = ''
        " Disable default mappings
        let g:EasyMotion_do_mapping = 0

        " Enable smartcase
        let g:EasyMotion_smartcase = 1

        nmap , <Plug>(easymotion-overwin-f2)
        '';
      }
    ];
  };
}
