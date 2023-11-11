# --- modules/misc/gtk.nix
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
{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
with lib; let
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.misc.gtk;
  _ = mkOverrideAtModuleLevel;
in {
  # TODO create a theme system
  options.tensorfiles.misc.gtk = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the gtk system.
    '');

    home = {
      enable = mkHomeEnableOption;

      settings = mkHomeSettingsOption (_user: {});
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user: {
        home.packages = with pkgs; [dconf];

        gtk = {
          enable = _ true;
          theme = {
            name = _ "Arc-Dark";
            package = _ pkgs.arc-theme;
          };

          iconTheme = {
            name = _ "Arc";
            package = _ pkgs.arc-icon-theme;
          };
        };
      });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
