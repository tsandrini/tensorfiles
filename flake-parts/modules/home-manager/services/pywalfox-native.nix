# --- flake-parts/modules/home-manager/services/pywalfox-native.nix
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
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    getExe
    mkPackageOption
    ;

  cfg = config.tensorfiles.hm.services.pywalfox-native;

  pywalfoxUpdateHandleSocket = pkgs.writeShellScript "pywalfox-update-handle-socket" ''
    set -euo pipefail

    # TODO: Not sure why, but thunderbird creates a stale socket and the client
    # is then unable to send the update commands to the native messaging hosts
    # so I temporarily just delete it
    sock=/tmp/pywalfox_socket
    if [ ! -S "$sock" ]; then
      rm -f $sock 2>/dev/null
    fi

    exec ${getExe cfg.package} update
  '';
in
{
  options.tensorfiles.hm.services.pywalfox-native = {
    enable = mkEnableOption "Enable pywalfox-native helpers";
    package = mkPackageOption pkgs "pywalfox-native" { };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      systemd.user.services.pywalfox-update = {
        Unit = {
          Description = "Update Pywalfox theme";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = pywalfoxUpdateHandleSocket;
          PrivateTmp = false;
        };
      };

      systemd.user.paths.pywalfox-update = {
        Unit = {
          Description = "Run pywalfox update when wal colors.json changes";
          PartOf = [ "graphical-session.target" ];
        };
        Path = {
          PathChanged = "%h/.cache/wal/colors.json";
          Unit = "pywalfox-update.service";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    }
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
