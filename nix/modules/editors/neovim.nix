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
        let g:loaded_netrw = false
        let g:loaded_netrwPlugin = false
        let g:loaded_netrwSettings = false
        let g:loaded_netrwFileHandlers = false

        " Enable nerdfont
        let g:fern#renderer = "nerdfont"
        let g:fern#disable_default_mappings = true

        " I only use fern as a drawer opened via `m` and closed either by `q` or by
        " selecting and opening a node
        nnoremap <silent> m :Fern . -drawer -reveal=% -width=35 <CR><C-w>=

        " Setup close action for a further "open and close" mapping
        nnoremap <silent> <Plug>(fern-close-drawer) :<C-u>FernDo close -drawer -stay<CR>
        '';
      }
    ];
  };
}
