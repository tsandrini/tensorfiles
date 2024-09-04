# --- flake-parts/modules/nixvim/keymaps.nix
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

  cfg = config.tensorfiles.nixvim.keymaps;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.keymaps = {
    enable = mkEnableOption ''
      TODO
    '';

    remapEsc = {
      enable =
        mkEnableOption ''
          TODO
        ''
        // {
          default = true;
        };
    };

    tabNavigation = {
      enable =
        mkEnableOption ''
          TODO
        ''
        // {
          default = true;
        };
    };

    windowNavigation = {
      enable =
        mkEnableOption ''
          TODO
        ''
        // {
          default = true;
        };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      globals.mapleader = _ " ";
      globals.maplocalleader = _ " ";
    }
    # |----------------------------------------------------------------------| #
    {
      keymaps = [
        {
          mode = "n";
          key = "<leader>w";
          action = ":w<CR>";
          options = {
            desc = "Save file.";
          };
        }
        {
          mode = "n";
          key = "<leader>q";
          action = ":q<CR>";
          options = {
            desc = "Quit file.";
          };
        }
        {
          mode = "n";
          key = "<leader>r";
          action = ":noh<CR>";
          options = {
            desc = "Remove highlights.";
          };
        }
        {
          mode = "n";
          key = "<leader>t";
          action = ":terminal<CR>";
          options = {
            desc = "Open terminal.";
          };
        }
        {
          mode = "n";
          key = "<leader>Q";
          action = ":qall<CR>";
          options = {
            desc = "Quit all windows.";
          };
        }
      ];
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.windowNavigation.enable {
      keymaps = [
        {
          mode = "n";
          key = "<leader>s";
          action = ":split<CR>";
          options = {
            desc = "Split window below.";
          };
        }
        {
          mode = "n";
          key = "<leader>v";
          action = ":vsplit<CR>";
          options = {
            desc = "Split window right.";
          };
        }
        {
          mode = "n";
          key = "<leader>h";
          action = "<C-w>h";
          options = {
            desc = "Window left.";
          };
        }
        {
          mode = "n";
          key = "<leader>j";
          action = "<C-w>j";
          options = {
            desc = "Window below.";
          };
        }
        {
          mode = "n";
          key = "<leader>k";
          action = "<C-w>k";
          options = {
            desc = "Window above.";
          };
        }
        {
          mode = "n";
          key = "<leader>l";
          action = "<C-w>l";
          options = {
            desc = "Window right.";
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.tabNavigation.enable {
      keymaps = [
        {
          mode = "n";
          key = "J";
          action = ":tabprevious<CR>";
          options = {
            desc = "Move to previous tab.";
          };
        }
        {
          mode = "n";
          key = "K";
          action = ":tabnext<CR>";
          options = {
            desc = "Move to next tab.";
          };
        }
        {
          mode = "n";
          key = "<leader>n";
          action = ":tabnew<CR>";
          options = {
            desc = "New tab.";
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.remapEsc.enable {
      keymaps = [
        {
          mode = [
            "i"
            "c"
            # "v" # NOTE doesnt work and produces visual delay
          ];
          key = "jk";
          action = "<Esc>";
          options = {
            silent = true;
          };
        }
        {
          mode = [
            "i"
            "c"
            # "v" # NOTE doesnt work and produces visual delay
          ];
          key = "kj";
          action = "<Esc>";
          options = {
            silent = true;
          };
        }
        {
          mode = "t";
          key = "jk";
          action = "<C-\\><C-n>";
          options = {
            silent = true;
          };
        }
        {
          mode = "t";
          key = "kj";
          action = "<C-\\><C-n>";
          options = {
            silent = true;
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
