# --- flake-parts/modules/nixvim/plugins/utils/project-nvim.nix
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
{ config, lib, ... }:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.nixvim.plugins.utils.project-nvim;
  _ = mkOverrideAtNixvimModuleLevel;

  telescopeCheck = isModuleLoadedAndEnabled config "tensorfiles.nixvim.plugins.utils.telescope";
in
{
  options.tensorfiles.nixvim.plugins.utils.project-nvim = {
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
      plugins.project-nvim = {
        enable = _ true;
        enableTelescope = _ telescopeCheck;
        # NOTE DEFAULT produces too many false positives
        # settings.patterns = [ ".git" "_darcs" ".hg" ".bzr" ".svn" "Makefile" "package.json" ];
        settings.patterns = [
          ".git"
          ".projectfile"
        ];
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.withKeymaps && telescopeCheck) {
      keymaps = [
        {
          mode = "n";
          key = "<leader>pp";
          action = "<cmd>Telescope projects<CR>";
          options = {
            desc = "Telescope projects.";
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
