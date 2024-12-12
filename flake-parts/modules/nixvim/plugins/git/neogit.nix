# --- flake-parts/modules/nixvim/plugins/git/neogit.nix
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

  cfg = config.tensorfiles.nixvim.plugins.git.neogit;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.git.neogit = {
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
      plugins.neogit = {
        enable = _ true;
        settings = {
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.withKeymaps {
      keymaps = [
        {
          mode = "n";
          key = "<leader>gg";
          action = "<cmd>Neogit kind=vsplit<CR>";
          options = {
            desc = "Neogit";
          };
        }
        {
          mode = "n";
          key = "<leader>gb";
          action = "<cmd>Neogit branch<CR>";
          options = {
            desc = "Neogit branch";
          };
        }
        {
          mode = "n";
          key = "<leader>gF";
          action = "<cmd>Neogit fetch<CR>";
          options = {
            desc = "Neogit fetch";
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
