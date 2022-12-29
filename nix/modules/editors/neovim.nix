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
        vim.g.indentLine_char = "┆"
        vim.g.indentLine_color_term = 239
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
        vim.g.move_key_modifier = "C"
        '';
      }
      {
        plugin = fern-vim;
        config = ''
        -- Disable netrw
        vim.g.loaded_netrw = false
        vim.g.loaded_netrwPlugin = false
        vim.g.loaded_netrwSettings = false
        vim.g.loaded_netrwFileHandlers = false

        -- Enable nerdfont
        vim.g["fern#renderer"] = "nerdfont"

        -- Key mappings
        vim.g["fern#disable_default_mappings"] = true
        '';
      }
    ];
  };
}
