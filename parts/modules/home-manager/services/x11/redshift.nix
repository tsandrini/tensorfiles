# --- parts/modules/home-manager/services/x11/redshift.nix
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
  ...
}:
with builtins;
with lib; let
  cfg = config.tensorfiles.hm.services.x11.redshift;
  _ = mkOverride 700;
in {
  options.tensorfiles.hm.services.x11.redshift = with types; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      services.redshift = {
        enable = _ true;
        tray = _ true;
        provider = _ "manual";
        latitude = _ 50.1386267;
        longitude = _ 14.4295628;
        temperature.day = _ 5700;
        temperature.night = _ 3500;
        settings = {
          redshift = {
            gamma = _ 0.95;
            adjustment-method = _ "randr";
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);
}
