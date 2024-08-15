# --- flake-parts/modules/home-manager/programs/thunderbird.nix
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
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.programs.thunderbird;
  _ = mkOverrideAtHmModuleLevel;
in
{
  options.tensorfiles.hm.programs.thunderbird = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      # TODO setup systemd service
      home.packages = with pkgs; [ birdtray ];

      programs.thunderbird = {
        enable = _ true;
        profiles.default = {
          isDefault = _ true;
          withExternalGnupg = _ true;
          settings = {
            "datareporting.healthreport.uploadEnabled" = _ false;
            "calendar.timezone.useSystemTimezone" = _ true;
            "privacy.donottrackheader.enabled" = _ true;
            "pdfjs.enabledCache.state" = _ true;
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
