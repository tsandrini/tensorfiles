# --- flake-parts/modules/home-manager/programs/terminals/ghostty.nix
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
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkDankMaterialShellEnableOption;

  cfg = config.tensorfiles.hm.programs.terminals.ghostty;
  _ = mkOverrideAtHmModuleLevel;

  dmsCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.dank-material-shell")
    && cfg.dank-material-shell.enable;
in
{
  options.tensorfiles.hm.programs.terminals.ghostty = {
    enable = mkEnableOption ''
      TODO
    '';

    dank-material-shell = {
      enable = mkDankMaterialShellEnableOption;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.ghostty = {
        enable = _ true;
        systemd.enable = _ true;
        settings = {
          font-size = _ 10;
          cursor-style = _ "bar";
          cursor-style-blink = _ true;

          window-padding-x = _ 5;
          window-padding-y = _ 5;
          background-opacity = _ 0.8;
          window-show-tab-bar = _ "never";
          clipboard-read = _ "allow";
          clipboard-write = _ "allow";
          window-decoration = _ "server";
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf dmsCheck {
      programs.ghostty.settings.theme = _ "dankcolors";
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
