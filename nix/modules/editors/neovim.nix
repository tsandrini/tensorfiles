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
        type = "lua";
        config = ''
          vim.g.indentLine_char = '┆'
          vim.g.indentLine_color_term = 239
        '';
      }
      lexima-vim
      {
        plugin = vim-vsnip;
        type = "lua";
        config = ''
        '';
      }
      vim-vsnip-integ
      friendly-snippets
      {
        plugin = vim-move;
        type = "lua";
        config = ''
          vim.g.move_key_modifier = "C"
        '';
      }
      {
        plugin = fern-vim;
        type = "lua";
        config = ''
        '';
      }
      popup-nvim
      plenary-nvim
      {
        plugin = telescope-nvim;
        type = "lua";
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
        type = "lua";
        config = ''
          nvim.g.EasyMotion_do_mapping = false
          nvim.g.EasyMotion_smartcase = true

          vim.keymap.set("n", ",", "<Plug>(easymotion-overwin-f2)", {})
        '';
      }
    ];
  };
}
