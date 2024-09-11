# --- flake-parts/modules/nixvim/plugins/utils/telescope.nix
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

  cfg = config.tensorfiles.nixvim.plugins.utils.telescope;
  _ = mkOverrideAtNixvimModuleLevel;
in
{

  options.tensorfiles.nixvim.plugins.utils.telescope = {
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
      extraPackages = with pkgs; [
        ripgrep
        fzf
      ];

      plugins.telescope = {
        enable = _ true;
        extensions = {
          file-browser = {
            enable = _ true;
          };
          fzf-native = {
            enable = _ true;
          };
          frecency = {
            enable = _ true;
          };
        };
        settings = {
          defaults.prompt_prefix = _ "🔍";
          pickers.colorscheme.enable_preview = _ true;
        };
        keymaps = mkIf cfg.withKeymaps {
          "<leader>/" = {
            action = "live_grep";
            options = {
              desc = "Grep in project";
              silent = true;
            };
          };
          "<leader><leader>" = {
            action = "find_files";
            options = {
              desc = "Find files";
              silent = true;
            };
          };
          "<leader>pg" = {
            action = "git_commits";
            options = {
              desc = "Telescope git commits";
              silent = true;
            };
          };
          "<leader>pf" = {
            action = "find_files";
            options = {
              desc = "Telescope files";
              silent = true;
            };
          };
          "<leader>ph" = {
            action = "man_pages";
            options = {
              desc = "Telescope man pages";
              silent = true;
            };
          };
          "<leader>pl" = {
            action = "colorscheme";
            options = {
              desc = "Telescope colorschemes";
              silent = true;
            };
          };
          "<leader>ps" = {
            action = "snippets";
            options = {
              desc = "Telescope snippets";
              silent = true;
            };
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
