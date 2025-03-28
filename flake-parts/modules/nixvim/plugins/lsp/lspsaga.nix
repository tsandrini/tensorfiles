# --- flake-parts/modules/nixvim/plugins/lsp/lspsaga.nix
#
# Author:  tsandrini <t@tsandrini.sh>
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

  cfg = config.tensorfiles.nixvim.plugins.lsp.lspsaga;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.lsp.lspsaga = {
    enable = mkEnableOption ''
      TODO
    '';

    withKeymaps =
      mkEnableOption ''
        Enable the related included keymaps.
      ''
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      plugins.lspsaga = {
        enable = _ true;
        lightbulb = {
          enable = _ false;
          virtualText = _ false;
        };
        hover = {
          openCmd = _ "!firefox";
        };
        # ui.border = "${opts.border}";
        scrollPreview = {
          scrollDown = _ "<c-d>";
          scrollUp = _ "<c-u>";
        };
        symbolInWinbar = {
          enable = _ true; # Breadcrumbs
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.withKeymaps {
      keymaps = [
        {
          mode = "n";
          key = "<leader>ca";
          action = "<cmd>Lspsaga code_action<CR>";
          options = {
            silent = true;
            desc = "LSP code action.";
          };
        }
        {
          mode = "n";
          key = "gd";
          action = "<cmd>Lspsaga peek_definition<CR>";
          options = {
            silent = true;
            desc = "LSP Peek definition.";
          };
        }
        {
          mode = "n";
          key = "<leader>cd";
          action = "<cmd>Lspsaga peek_definition<CR>";
          options = {
            silent = true;
            desc = "LSP Peek definition.";
          };
        }
        {
          mode = "n";
          key = "gr";
          action = "<cmd>Lspsaga finder<CR>";
          options = {
            silent = true;
            desc = "LSP Find references.";
          };
        }
        {
          mode = "n";
          key = "<leader>cR";
          action = "<cmd>Lspsaga finder<CR>";
          options = {
            silent = true;
            desc = "LSP Find references.";
          };
        }
        {
          mode = "n";
          key = "gI";
          action = "<cmd>Lspsaga finder<CR>";
          options = {
            silent = true;
            desc = "LSP Find implementations.";
          };
        }
        {
          mode = "n";
          key = "<leader>ci";
          action = "<cmd>Lspsaga finder<CR>";
          options = {
            silent = true;
            desc = "LSP Find implementations.";
          };
        }
        {
          mode = "n";
          key = "gT";
          action = "<cmd>Lspsaga peek_type_definition<CR>";
          options = {
            silent = true;
            desc = "LSP Peek type definition.";
          };
        }
        {
          mode = "n";
          key = "<leader>ct";
          action = "<cmd>Lspsaga peek_type_definition<CR>";
          options = {
            silent = true;
            desc = "LSP Peek type definition.";
          };
        }
        {
          mode = "n";
          key = "<C-k>";
          action = "<cmd>Lspsaga hover_doc<CR>";
          options = {
            silent = true;
            desc = "LSP Hover.";
          };
        }
        {
          mode = "n";
          key = "<C-k>";
          action = "<cmd>Lspsaga hover_doc<CR>";
          options = {
            silent = true;
            desc = "LSP Hover.";
          };
        }
        {
          mode = "n";
          key = "<leader>cr";
          action = "<cmd>Lspsaga rename<CR>";
          options = {
            silent = true;
            desc = "LSP Rename.";
          };
        }
        {
          mode = "n";
          key = "<leader>co";
          action = "<cmd>Lspsaga outline<CR>";
          options = {
            silent = true;
            desc = "LSP Outline toggle.";
          };
        }
        {
          mode = "n";
          key = "<leader>cw";
          action = "<cmd>Lspsaga outline<CR>";
          options = {
            silent = true;
            desc = "LSP Symbols (outline).";
          };
        }
        {
          mode = "n";
          key = "<leader>t";
          action = "<cmd>Lspsaga term_toggle<CR>";
          options = {
            silent = true;
            desc = "LSP Terminal toggle.";
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
