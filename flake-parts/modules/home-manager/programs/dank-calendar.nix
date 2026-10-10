# --- flake-parts/modules/home-manager/programs/dank-calendar.nix
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
{ localFlake, inputs }:
{ config, lib, ... }:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.programs.dank-calendar;
  _ = mkOverrideAtHmModuleLevel;
in
{
  options.tensorfiles.hm.programs.dank-calendar = {
    enable = mkEnableOption ''
      DankCalendar (`dcal`), the calendar app and sync daemon behind the
      "Dank Calendar" backend of DankMaterialShell, started at login via its
      user service. Accounts are added in the app or with `dcal account add`.
    '';
  };

  imports = [
    inputs.dankcalendar.homeModules.default
  ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.dank-calendar = {
        enable = _ true;
        systemd.enable = _ true;
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
