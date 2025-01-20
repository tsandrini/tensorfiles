# --- flake-parts/modules/nixvim/plugins/editor/neo-tree.nix
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
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel;

  cfg = config.tensorfiles.nixvim.plugins.editor.neo-tree;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.editor.neo-tree = {
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
      extraPlugins = with pkgs.vimPlugins; [
        nui-nvim
        nvim-web-devicons
      ];

      plugins.neo-tree = {
        enable = _ true;
        closeIfLastWindow = _ true;
        addBlankLineAtTop = _ false;
        enableGitStatus = _ true;
        enableRefreshOnWrite = _ true;
        enableDiagnostics = _ true;
        sources = [
          "filesystem"
          "buffers"
          "git_status"
          "document_symbols"
        ];

        filesystem = {
          bindToCwd = _ false;
          useLibuvFileWatcher = _ true;
          followCurrentFile = {
            enabled = _ true;
          };
        };

        window = {
          mappings = {
            "l" = "open";
            "h" = "close_node";
          };
        };

        defaultComponentConfigs = {
          indent = {
            withExpanders = _ true;
            expanderCollapsed = _ "";
            expanderExpanded = _ " ";
            expanderHighlight = _ "NeoTreeExpander";
          };
          gitStatus = {
            symbols = {
              added = _ " ";
              conflict = _ "󰩌 ";
              deleted = _ "󱂥";
              ignored = _ " ";
              modified = _ " ";
              renamed = _ "󰑕";
              staged = _ "󰩍";
              unstaged = _ "";
              untracked = _ "";
            };
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.withKeymaps {
      keymaps = [
        {
          mode = "n";
          key = "m";
          action = "<cmd>Neotree<CR>";
          options = {
            silent = true;
            desc = "eotree Open";
          };
        }
        # {
        #   mode = "n";
        #   key = "<leader>b";
        #   action = "<cmd>Neotree buffers focus<CR>";
        #   options = {
        #     silent = true;
        #     desc = "Neotree buffers focus";
        #   };
        # }
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
