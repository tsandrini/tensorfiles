# --- flake-parts/modules/nixvim/settings.nix
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
{ localFlake }:
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel;

  cfg = config.tensorfiles.nixvim.settings;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.settings = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      clipboard = {
        providers.wl-copy.enable = true;
      };

      opts = {
        number = _ true; # Show line numbers
        relativenumber = _ true; # Show relative line numbers
        clipboard = _ "unnamedplus"; # Use the system clipboard

        formatoptions = [
          "l" # Long lines are not broken in insert mode
        ];
        rulerformat = _ "%l:%c"; # Show the line and column number of the cursor
        foldenable = _ false; # Disable folding by default
        colorcolumn = _ "80";

        wildmenu = _ true; # Show a list of matching files when tab completing
        # TODO maybe use wilder.nvim plugin
        wildmode = _ "longest:full,full"; # Tab complete as much as possible
        wildignorecase = _ true; # Ignore case when tab completing

        tabstop = _ 2; # Number of spaces that represent a <TAB>
        softtabstop = _ 0; # Number of spaces that a <TAB> counts for while editing
        expandtab = _ true; # Use spaces instead of tabs
        shiftwidth = _ 2; # Number of spaces to use for each step of (auto)indent
        smarttab = _ true; # Pressing the Tab key behaves differently depending on the context
        smartindent = _ true; # Enable smart indentation
        shiftround = _ true; # Round indent to multiple of shiftwidth

        scrolloff = _ 8; # Minimum number of screen lines to keep above and below the cursor
        mouse = _ "a"; # Full mouse support

        list = _ true; # Show invisible characters
        listchars = {
          tab = _ "»·"; # Show tabs as »
          trail = _ "•"; # Show trailing spaces as ·
          extends = _ "#"; # Show lines that wrap as #
          nbsp = _ "."; # Show non-breaking spaces as .
        };

        ignorecase = _ true; # Ignore case when searching
        smartcase = _ true; # Override 'ignorecase' if the search pattern contains uppercase characters
        showmatch = _ true; # Highlight matching parenthesis

        undofile = _ true;
        undodir = _ "/home/tsandrini/.cache/nvim/undodir";
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
