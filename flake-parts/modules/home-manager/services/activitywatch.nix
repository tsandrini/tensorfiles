# --- flake-parts/modules/home-manager/services/activitywatch.nix
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
with builtins;
with lib;
let
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.services.activitywatch;
  _ = mkOverrideAtHmModuleLevel;
in
{
  options.tensorfiles.hm.services.activitywatch = with types; {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      services.activitywatch = {
        enable = _ true;
        package = _ pkgs.aw-server-rust;
        watchers = {
          awatcher.package = _ pkgs.awatcher;
          # awatcher.package = _ localFlake.packages.${system}.awatcher;
          # aw-watcher-window.package = _ pkgs.aw-watcher-window;
          # aw-watcher-afk.package = _ pkgs.aw-watcher-afk;
        };
      };

      systemd.user.services.activitywatch-watcher-awatcher = {
        Unit.After = [ "activitywatch.service" ];
      };

      systemd.user.services.aw-qt = {
        Unit = {
          After = [ "activitywatch.service" ];
          Description = _ "Qt Tray Application for ActivityWatch";
        };
        Service = {
          ExecStart = _ "${pkgs.aw-qt}/bin/aw-qt";
          RestartSec = _ 5;
          Restart = _ "unless-stopped";
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
