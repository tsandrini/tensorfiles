# --- modules/services/x11/redshift.nix
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
{ config, lib, pkgs, ... }:
with builtins;
with lib;
let
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.services.x11.redshift;
  _ = mkOverrideAtModuleLevel;
in {
  options.tensorfiles.services.x11.redshift = with types;
    with tensorfiles.options; {

      enable = mkEnableOption (mdDoc ''
        Enables NixOS module that configures/handles the x11 redshift service
      '');

      home = {
        enable = mkHomeEnableOption;

        settings = mkHomeSettingsOption (_user: { });
      };
    };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user:
        let userCfg = cfg.home.settings."${_user}";
        in {
          services.redshift = {
            enable = _ true;
            tray = _ true;
            provider = _ "manual";
            latitude = _ 50.1386267;
            longitude = _ 14.4295628;
            temperature.day = _ 5700;
            temperature.night = _ 3500;
          };
        });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}